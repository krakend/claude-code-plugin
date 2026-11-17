#!/usr/bin/env python3
"""Assemble a dashboard from recipe panels and a short layout, so panels are never retyped.

  build_dashboard.py --panels panels.json [--panels more.json] --layout layout.json --out <uid>.json

panels.json: written by get_dashboard_recipes with panels_file ({"order", "panels": {id: panel}}).
For topic dashboards, take the rows from that call's blueprints[<intent>] (title + recipe ids).
layout.json:
  {
    "uid": "krakend-ai-gateway-overview",
    "title": "Gateway overview",
    "description": "The user's request, in one sentence",
    "tags": ["overview"],                      # krakend + generated-by-claude are added
    "refresh": "30s", "time_from": "now-1h",  # optional
    "rows": [
      {"title": "Overview", "panels": ["traffic.requests_in_range", "errors.ratio_5xx",
                                        {"id": "latency.percentiles_in_range", "w": 8}]},
      {"title": "Traffic", "panels": ["traffic.rps_by_endpoint", "traffic.rps_by_status"]},
      {"title": "Custom", "panels": [{"panel": { ...a panel you wrote... }, "w": 12, "h": 8}]}
    ]
  }
A panel entry is a recipe id, or an object with "id" (recipe) or "panel" (your own JSON) plus
optional "w", "h", "title", "description" overrides. Default sizes: stat/gauge 4x4 (8x4 for a stat
with several values), piechart 6x8, everything else 12x8. In each row, stats come first on their
own lines; panels flow left to right, wrap at 24 columns, and each line is widened to fill 24
(panels with an explicit "w" keep it). A pie chart in a row of two or more stat lines stands beside
them, as tall as them. One or two stats in a row of graphs make a narrow column beside the first
graph (one stat 6 wide, two stacked 6 wide). Stat lines are\nchosen so single-value stats share one width (pie charts may widen, multi-value stats may move).. Variables come from
the skeleton, keeping only the ones the queries use. Check the result with the lint_dashboard tool.
"""
import argparse
import copy
import math
from itertools import combinations
import json
import re
import sys
from pathlib import Path

SKELETON = Path(__file__).resolve().parent.parent / "assets" / "dashboard-skeleton.json"
SIZES = {"stat": (4, 4), "gauge": (4, 4), "piechart": (6, 8)}


def load_panels(paths):
    panels = {}
    for p in paths:
        data = json.loads(Path(p).read_text())
        panels.update(data.get("panels", data))
    return panels


def balance(group, width=24):
    """Split panels into lines of at most `width` columns, spread evenly over the lines they need
    (7 stats -> 4 + 3, not 6 + 1)."""
    n = max(1, -(-sum(i["w"] for i in group) // width))
    while True:
        target = sum(i["w"] for i in group) / n
        out, cur, x = [], [], 0
        for it in group:
            if cur and (x + it["w"] > width or (x >= target and len(out) < n - 1)):
                out.append(cur)
                cur, x = [], 0
            cur.append(it)
            x += it["w"]
        out.append(cur)
        if len(out) <= n or n > len(group):
            return out
        n += 1


def fill(line, width=24):
    """Widen the panels without an explicit width so the line uses all `width` columns."""
    free = [i for i in line if not i["fixed"]]
    gap = width - sum(i["w"] for i in line)
    if gap <= 0 or not free:
        return
    total = sum(i["w"] for i in free)
    shares = [gap * i["w"] / total for i in free]
    for i, sh in zip(free, shares):
        i["w"] += int(sh)
    # hand out the columns lost to rounding, largest remainder first
    left = width - sum(i["w"] for i in line)
    for idx in sorted(range(len(free)), key=lambda k: shares[k] - int(shares[k]), reverse=True)[:left]:
        free[idx]["w"] += 1


def block(lines, w):
    """Several lines stacked in one slot of `w` columns (a column of stats beside a graph or a pie)."""
    return {"lines": lines, "w": w, "h": sum(max(i["h"] for i in ln) for ln in lines), "fixed": True}


def best_stat_lines(small, sides):
    """Lines of stats where every single-value stat ends up the same width (multi-value stats
    count double). Tries each side width (columns kept for pie charts), the given order and the
    multi-value stats moved elsewhere in it, and 1-4 lines; returns (side, lines) or None."""
    units = lambda ln: sum(2 if i["w"] > 4 else 1 for i in ln)
    orders = [list(small)]
    for m in [i for i in small if i["w"] > 4]:
        rest = [i for i in small if i is not m]
        orders += [rest[:k] + [m] + rest[k:] for k in range(len(rest) + 1)]
    best = None
    for side in sides:
        width = 24 - side
        for oi, order in enumerate(orders):
            n_items = len(order)
            for n in range(1, min(4, n_items) + 1):
                for cuts in combinations(range(1, n_items), n - 1):
                    bounds = (0, *cuts, n_items)
                    lns = [order[a:b] for a, b in zip(bounds, bounds[1:])]
                    if any(units(ln) * 4 > width for ln in lns):
                        continue
                    us = [width / units(ln) for ln in lns]
                    if any(u > 8 for u in us):
                        continue  # stats wider than 8 look empty
                    # integer columns: 4.5 means a 5/4 mix, so score on ceil/floor
                    score = (max(math.ceil(u) for u in us) - min(math.floor(u) for u in us), n, side, oi > 0)
                    if best is None or score < best[0]:
                        best = (score, side, lns)
    return best and (best[1], best[2])


def layout_row(items):
    """Arrange a row's panels into lines of slots; a slot is a panel or a block of stacked lines.
    - Stats come first on their own lines, balanced and widened to 24 columns.
    - Pie charts in a row of stats that needs two lines or more stand beside the stats, as tall
      as them; otherwise they are treated like graphs.
    - One or two stats in a row of graphs make a narrow column beside the first graph instead of a
      line of their own: one stat 6 wide at graph height, two stacked 6 wide, half height each.
    - Graphs flow left to right, balanced and widened to 24 columns."""
    pies = [i for i in items if i["panel"].get("type") == "piechart" and "h" not in i.get("entry", {})]
    small = [i for i in items if i["h"] <= 4 and i not in pies]
    big = [i for i in items if i["h"] > 4 and i not in pies]
    lines = []
    if small and all(not i["fixed"] for i in small):
        best = best_stat_lines(small, [sum(p["w"] for p in pies) + extra for extra in (0, 2)] if pies else [0])
        if best and (not pies or len(best[1]) >= 2):
            side, stat_lines = best
            width = 24 - side
            for ln in stat_lines:
                fill(ln, width)
            if pies:
                stats = block(stat_lines, width)
                for p in pies:
                    p["w"] += (side - sum(q["w"] for q in pies)) // len(pies)
                    p["h"] = stats["h"]
                    p["fixed"] = True
                lines.append([stats] + pies)
                pies = []
            else:
                lines += stat_lines
            small = []
    big = pies + big
    if big and small and len(small) <= 2 and sum(i["w"] for i in small) <= 8:
        gh = big[0]["h"]
        if len(small) == 1:
            s = small[0]
            s["h"] = gh
            if not s["fixed"]:
                s["w"] = 6  # 4 cuts the title
            s["fixed"] = True
            col = s
        else:
            for s in small:
                s["h"] = gh // 2
            col = block([[s] for s in small], max(6, *(s["w"] for s in small if s["fixed"]), 0))
            for s in small:
                s["w"] = col["w"]
        small, big = [], [col] + big
    for group in (small, big):
        if group:
            for ln in balance(group):
                fill(ln)
                lines.append(ln)
    return lines


def place(line, x, y, out, next_id):
    """Give every panel of a line its gridPos (blocks place their own lines, stacked)."""
    for slot in line:
        if "lines" in slot:
            yy = y
            for ln in slot["lines"]:
                next_id = place(ln, x, yy, out, next_id)
                yy += max(i["h"] for i in ln)
        else:
            panel = slot["panel"]
            panel["id"] = next_id
            panel["gridPos"] = {"h": slot["h"], "w": slot["w"], "x": x, "y": y}
            next_id += 1
            out.append(panel)
        x += slot["w"]
    return next_id


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--panels", action="append", default=[], help="panels_file from get_dashboard_recipes (repeatable)")
    ap.add_argument("--layout", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--skeleton", default=str(SKELETON))
    args = ap.parse_args()

    recipes = load_panels(args.panels)
    layout = json.loads(Path(args.layout).read_text())
    dash = json.loads(Path(args.skeleton).read_text())
    errors = []

    dash["uid"] = layout["uid"]
    dash["title"] = layout["title"]
    dash["description"] = layout.get("description", "")
    dash["tags"] = ["krakend", "generated-by-claude"] + [t for t in layout.get("tags", [])
                                                         if t not in ("krakend", "generated-by-claude")]
    if "refresh" in layout:
        dash["refresh"] = layout["refresh"]
    if "time_from" in layout:
        dash["time"] = {"from": layout["time_from"], "to": "now"}

    out, next_id, y = [], 1, 0
    for row in layout.get("rows", []):
        out.append({"id": next_id, "type": "row", "title": row["title"], "collapsed": False,
                    "gridPos": {"h": 1, "w": 24, "x": 0, "y": y}, "panels": []})
        next_id += 1
        y += 1
        items = []
        for entry in row.get("panels", []):
            if isinstance(entry, str):
                entry = {"id": entry}
            if "panel" in entry:
                panel = copy.deepcopy(entry["panel"])
            elif entry.get("id") in recipes:
                panel = copy.deepcopy(recipes[entry["id"]])
            else:
                errors.append(f"row {row['title']!r}: recipe {entry.get('id')!r} not in the panels files "
                              "(ask get_dashboard_recipes for it, or pass the right --panels)")
                continue
            for k in ("title", "description"):
                if k in entry:
                    panel[k] = entry[k]
            dw, dh = SIZES.get(panel.get("type"), (12, 8))
            if panel.get("type") == "stat" and len(panel.get("targets", [])) > 1:
                dw = 8  # several values in one stat (p50/p90/p95/p99) need room
            items.append({"panel": panel, "w": entry.get("w", dw), "h": entry.get("h", dh), "fixed": "w" in entry,
                          "entry": entry})
        for line in layout_row(items):
            next_id = place(line, 0, y, out, next_id)
            y += max(slot["h"] for slot in line)
    dash["panels"] = out

    used = set()
    for p in out:
        for t in p.get("targets", []):
            used.update(re.findall(r"\$\{?([A-Za-z_]\w*)", t.get("expr", "")))
    skeleton_vars = {v["name"]: v for v in dash["templating"]["list"]}
    for v in sorted(used - set(skeleton_vars) - {"datasource"}):
        if not v.startswith("__"):
            errors.append(f"queries use ${v}, which the skeleton doesn't define: add the variable to the output by hand")
    dash["templating"]["list"] = [v for n, v in skeleton_vars.items() if n == "datasource" or n in used]

    if errors:
        print("ERROR:\n  " + "\n  ".join(errors))
        sys.exit(1)
    Path(args.out).write_text(json.dumps(dash, indent=2) + "\n")
    # Compact copy to pass to update_dashboard: same dashboard, ~40% fewer characters to send.
    compact = Path(args.out).with_suffix(".min.json")
    compact.write_text(json.dumps(dash, separators=(",", ":")) + "\n")
    n = sum(1 for p in out if p["type"] != "row")
    print(f"{args.out}: {n} panels in {len(layout.get('rows', []))} rows, variables: "
          f"{', '.join(v['name'] for v in dash['templating']['list'])}")
    print(f"{compact}: the same, compact ({compact.stat().st_size // 1000} KB): pass this one to update_dashboard")


if __name__ == "__main__":
    main()
