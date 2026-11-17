---
name: krakend-dashboards
description: Create or modify Grafana dashboards for KrakenD API Gateway metrics from a natural-language request. Use when the user asks for a KrakenD dashboard, panel, or graph, or asks to visualize or monitor KrakenD traffic, latency, errors, backends, circuit breakers, rate limits or runtime in Grafana ("build me a dashboard for my gateway", "add a panel with p99 per endpoint", "why is /orders slow, show me in Grafana", "dashboard for the backends behind the circuit breaker"). Uses the Grafana MCP server bundled with this plugin and the KrakenD MCP server's observability tools.
---

# KrakenD dashboards from natural language

You turn a request in plain words into a working Grafana dashboard backed by KrakenD's
OpenTelemetry metrics in Prometheus. Success means every panel's query works and matches what
the user's KrakenD config produces, so it shows real data wherever that gateway is scraped. Valid
JSON is not enough.

The Grafana you can reach is not always the one watching this gateway: people often design
dashboards from a production config on a local or staging Grafana with no KrakenD data, and
import them later. **An empty datasource is fine: then the config is the source of truth**
(config-only mode, step 2).

**Every dashboard must be portable to the user's production Grafana.** Building on a dev or
local Grafana is optional; the exported JSON (the local `<uid>.json`) is the deliverable and must
import into another Grafana unchanged. So nothing from the environment you can query goes into
it: no datasource uids, no scrape label values (`job`, `instance`, hosts and ports), no variable
selections, no thresholds tuned to dev latency, no panels dropped because the dev machine can't
produce them. What it may contain comes from the KrakenD config (routes, backends, breaker and
model names), which is what runs in production. Details in `dashboard-conventions.md` →
Portability.

Bundled files (read them when the step says so, not all upfront, with the Read tool: they live
outside the project, where shell commands like `head` or `cat` may be blocked; run the scripts
with `python3 "<full path>"`):

- `${CLAUDE_PLUGIN_ROOT}/skills/krakend-dashboards/references/dashboard-conventions.md`: uid, tags, variables, layout, units, portability
- `${CLAUDE_PLUGIN_ROOT}/skills/krakend-dashboards/assets/dashboard-skeleton.json`: starting JSON with the standard variables
- `${CLAUDE_PLUGIN_ROOT}/skills/krakend-dashboards/scripts/build_dashboard.py`: lays out recipe panels from a short layout file

Tools: the `grafana` MCP server from this plugin (dashboards, Prometheus queries, rendering) and
the `krakend` MCP server from `krakend-ai-assistant`: docs, config validation, feature templates,
and the KrakenD metrics knowledge this skill relies on: `get_metrics_catalog` (what each metric
means), `analyze_config_observability` (what a config produces, and its gaps),
`get_dashboard_recipes` (tested PromQL, ready panels and topic layouts) and `lint_dashboard`.

If those four tools aren't listed, the installed `krakend-ai-assistant` is too old: tell the user
to update it (`claude plugin marketplace update krakend`, then
`claude plugin update krakend-ai-assistant@krakend`) and restart Claude Code. Don't build a
dashboard from memory without them.

## Before anything: the Grafana MCP server must be connected

Check that the `grafana` MCP tools are available (`list_datasources`, `search_dashboards`,
`update_dashboard`...). If they aren't, **stop and help fix the connection**. Don't build
the dashboard another way:
- Ask the user to run `/mcp` and look at the `grafana` server (plugin `krakend-observability`).
- Not listed at all: the plugin's Grafana URL / token settings are probably missing. Configure
  them through `/plugin` (krakend-observability → configure) and run `/reload-plugins`.
- Listed but failed: Docker must be running; the URL must be the one they open in the browser;
  the token must belong to a service account with the Editor role.
- Connected, but calls fail with 401/403: the token is wrong, expired or from a Grafana that was
  reset. Put a new token in the plugin settings (`/plugin` → krakend-observability → configure),
  then restart Claude Code (exit and run `claude --continue`): `/reload-plugins` may keep the
  running Grafana MCP server with the old token.

**Never** call Grafana's HTTP API directly (curl, scripts) and never use tokens found in files,
environment variables or shell history. The MCP server is the only way this skill touches
Grafana; the guardrails below assume it. You may still prepare and lint the dashboard JSON
locally while the user fixes the connection, and say that you did.

## Workflow

### 1. Understand the request

Work out:
- **Question behind it**: overview, an incident ("why is X slow"), a specific feature (circuit
  breaker, rate limit, backends), capacity/runtime, or a demo.
- **Scope**: all endpoints, some endpoints, some backends, one node.
- **New or edit**: if they reference an existing dashboard ("add", "change", "the one we made"),
  find it with `search_dashboards` (tag `generated-by-claude`) and edit it in place.

Ask at most one clarifying question, and only if the answer changes which metrics you use.
Otherwise choose sensible defaults and say which ones you chose. Where the dashboard will be used
(dev machine vs Linux production) is one of those questions: never leave a panel out because the
machine you can query can't produce it; keep it, or ask (see `dashboard-conventions.md`).

If a KrakenD config file is available (in the project, or the user points to one), call
`analyze_config_observability` with it (render Flexible Configuration templates first). It
returns the enabled metric groups, the label values to expect (endpoint and backend routes,
circuit breaker names, LLM models, topics), async agents, rate-limited endpoints, warnings, and `gaps`: config
changes that would enable missing metrics, with snippets.

**Stop if the config exports no metrics**, that is, it has no `telemetry/opentelemetry` block
(`telemetry_enabled: false`). Don't build a dashboard, and don't design one against a modified or
scratch copy of the config. (A config that only exports via OTLP, with no Prometheus exporter, is
fine: build normally, the recipes assume a store that translates names like Prometheus does.)

Instead, reply briefly: this config exports no metrics, so a dashboard would stay empty. Then
show the snippet (from the `extra_config.telemetry/opentelemetry` gap, or
`get_feature_config_template`), explaining what `go_metrics`, `process_metrics` and the backend
options add. Ask "Want me to add it to krakend.json and validate it?" On a yes: edit the real
config, run `validate_config`, and tell them to redeploy/restart KrakenD and have Prometheus
scrape the exporter port. Then build the dashboard from the updated config (Prometheus doesn't
need to have data yet).

**Keep the gaps for the user: they are one of the most useful things you can give them.** Note
which gaps relate to the request (a runtime dashboard without `go_metrics`, a backend dashboard
without `round_trip`...), plus the `unavailable` recipes from step 3. They get their own section in
your reply (step 8), never in the dashboard. If no config is available, you can't
know what's off: say in the reply that you can suggest config changes if they point you to it.

### 2. Discover what actually exists. Never skip this step.

The installed KrakenD version and scrape config decide the metric names and labels, so never
rely on memory or on the catalog alone.

1. `list_datasources`: pick the Prometheus datasource. If there are several, prefer one whose
   name mentions krakend/gateway, else ask.
2. `list_prometheus_metric_names` with the regex
   `^(up|http_.*|krakend_.*|go_.*|process_.*|messaging_.*|websocket_.*|db_client_.*)$`: see which families
   exist **so far**. If no KrakenD metric exists at all, work in **config-only mode** (below);
   it is not an error. Missing families are NOT a reason to leave panels out: error, timeout, breaker, Kafka, LLM...
   metrics only appear after the first event of their kind. **The config decides what the
   dashboard has; live data only tells you what happened so far.** The reverse also happens:
   Prometheus lists names from everything scraped within its retention (an earlier config, another
   gateway). A family the config doesn't enable is usually history: check with an instant
   `count(<metric>)` before trusting it, and don't report it as a tool error. The same goes for
   label values (old routes, agents, breakers): `count by (http_route) (http_server_duration_count)`
   as an instant query shows what the current process exports; use the config's names.
   **Detect the naming convention.** If `http_server_request_duration_seconds_bucket` exists
   instead of `http_server_duration_bucket`, the user has `semantic_convention: "1.27"`.
   `get_dashboard_recipes` converts recipes for you (`semantic_convention: "auto"`); for queries
   you write yourself, `lint_dashboard` with `semantic_convention: "1.27"` gives their converted
   form (step 5). Never mix the two conventions in one dashboard.
3. `list_prometheus_label_names` / `list_prometheus_label_values` on `http_server_duration_count`:
   find `job`, `instance` (and `app` if present) and the real `http_route` values.
4. Look up meanings with `get_metrics_catalog` (filter by `groups`, `query` or `names`; pass
   `semantic_convention: "auto"` and the `metric_names` from point 2 to get names in the user's
   convention, and use `not_found` to spot live metrics the catalog doesn't know). When the live
   names differ from the catalog,
   **the live names win** (if the config's `semantic_convention` says otherwise, the dev
   gateway isn't running this config: ask which one production uses): use them and move on. Only mention it to the user if it changes what a
   panel shows.

**Config-only mode** (no KrakenD metrics in the datasource): build from the config.
- Needs a config. Without one there is nothing to go on: ask for it (one question), or, if they
  just want a generic dashboard, use the default recipes and say it's untested against their setup.
- Naming convention: from the config (`semantic_convention` in `analyze_config_observability`).
  Pass `semantic_convention: "auto"` and no `metric_names` to `get_dashboard_recipes`: it falls
  back to the config, and no recipe gets flagged `no_data_yet`.
- Scrape labels: default `job` and `instance` (variables with "All"). Ask about `app` or other
  labels only if the user mentions them.
- Endpoint, backend, breaker and model names: the analysis `label_values` (they are predictions,
  but the best you have).

### 3. Design the panels

- Call `get_dashboard_recipes` with the intents, `semantic_convention: "auto"`, the
  `metric_names` from step 2 (the whole list as returned, not a selection: a missing name marks
  its recipes `no_data_yet`), the scrape labels you found (`job`, `instance`, `app`...) and the
  config if you have one. It returns recipes with selectors filled in, names already converted
  to the user's convention, config-specific parameters (rate-limited routes) applied, and an
  `unavailable` list with reasons and fixes (only for things the config doesn't enable). Read
  each recipe's `agent_notes`: they are for you (caveats, what to tell the user), never for the panel. Mention
  unavailable recipes relevant to the request. Recipes flagged `no_data_yet` are **valid**: the
  config enables them but nothing of that kind has happened yet. Include them like any other.
  Don't pass
  `only_with_data` unless the user explicitly asks for panels with current data only.
  For a dashboard, pass `panels_file: "<uid>.panels.json"`: the ready panels (thresholds, colors,
  units, legends) go to that file and the result only lists ids, titles and flags. One call can
  cover all the intents you need. Don't retype panels: step 4 builds the dashboard from that file.
  (`format: "grafana_panel"` without a file returns them inline, limited to ~45 KB.)
- Write new PromQL only when no recipe fits, and keep to the same patterns (`sum by (le, ...)`
  before `histogram_quantile`, `$__rate_interval`).
- Read `dashboard-conventions.md` for layout, units, thresholds, legends and portability.
- Put what the user asked about first. For a question, add 2-4 context panels at most. For a
  dashboard about a topic, build all of it, not a sample:
  - `overview`, `runtime`, `backends`, `agents`: the result's `blueprints[<intent>]` lists the
    rows in order, with the recipes this config enables (optional rows such as Kafka or AI in an
    overview appear only when the config has them). Use those rows as your layout, and read the
    blueprint's `notes`.
  - `websocket`, `kafka`, `redis`, `ai`: every recipe of the intent, stats first, client and
    backend side (or publish and consume) in separate rows.
- For "why is X slow" questions, use the layer breakdown (`layers.*_avg` recipes) pinned to that
  endpoint, plus backend p95 by `http_route` and `server_address`. Layer comparisons use
  averages, never several layers' p95 on one panel (histogram buckets make them look identical),
  and never across "All" endpoints (each layer measures a different set of requests).

### 4. Build the JSON

Write a short layout file (rows of recipe ids, see the header of `build_dashboard.py`) and build
`<uid>.json` in the working directory, where the user can version it:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/krakend-dashboards/scripts/build_dashboard.py" \
  --panels <uid>.panels.json --layout <uid>.layout.json --out <uid>.json
```

It fills uid, title, tags and the variables the queries use, sizes and places the panels. Panels
you write yourself go in the layout as `{"panel": {...}}`. Change a recipe panel through the
layout's overrides (`title`, `w`, `h`) or by editing `<uid>.json` afterwards, not by retyping it.

Config suggestions never go in the dashboard (no text panels or rows about missing
configuration): they belong in your reply only (step 8).

### 5. Verify before pushing

Call `lint_dashboard` with `dashboard: "<uid>.json"` (the file path), `uid_prefix: "krakend-ai-"`,
`required_tags: ["krakend", "generated-by-claude"]` and `expand: true`. On semconv 1.27 with
queries you wrote yourself, also pass `semantic_convention: "1.27"` and put the `converted` forms
into your layout (recipe queries are already converted).

- Fix every error, rebuild with `build_dashboard.py` and lint again. Fix warnings unless you have
  a reason not to.
- In config-only mode, still run the `expanded` queries you wrote or changed: Prometheus
  parses it even without data, so it catches syntax errors. Empty results are expected; don't
  remove anything for being empty. Skip the rest of this list and step 7.
- Run with `query_prometheus` (instant query is enough) the `expanded` queries you wrote or
  changed, plus one per recipe section. Recipe queries from `get_dashboard_recipes` whose metrics
  are all in `metric_names` are already tested and need no separate run. The point is to catch
  **broken** queries, not to delete quiet panels:
  - Query error: fix it.
  - Empty, and the metric is expected (recipe `no_data_yet`, or the catalog/analysis says the
    config enables it, or it depends on the OS/environment, like Linux-only metrics): **keep the
    panel as it is**. Don't add `noValue` texts or "no data until..." notes to it: an empty
    panel shows Grafana's plain "No data".
  - Empty, and the metric isn't expected from this config (wrong name, feature not enabled):
    fix or remove it, and say why.
  Tell the user in your reply (step 8) which panels are waiting for their first event.

### 6. Push

- Folder: find or create `KrakenD` (`search_folders`, `create_folder`).
- `update_dashboard` with the full dashboard JSON: read `<uid>.min.json` (the compact copy
  `build_dashboard.py` writes) and pass its content unchanged; edit `<uid>.json` and rebuild rather
  than changing JSON while pasting. Pass the folder uid, `overwrite: true` when editing
  your own uid, and a `message` describing the change (it shows up in version history).

### 7. Look at it

If rendering tools are available, render 2-3 key panels with `get_panel_image` and check them.
Pass relative times (`now-30m` to `now`): absolute RFC3339 times render a 1970 range.
Look for flat lines where you expected traffic, a wrong unit (latency in "ms" showing 0.4),
unreadable legends. Fix and re-push if needed. If rendering isn't available, skip this step and
don't mention it.

### 8. Report

The reply is for someone who wants a dashboard, not for the people who build these tools. Keep it
short and about their gateway:

1. **The dashboard**: link (`generate_deeplink` if available, else `<grafana_url>/d/<uid>`) and
   the local JSON file path, with one line on taking it to production: Dashboards → New → Import,
   upload the file, and pick their Prometheus in the Data source variable. If the Grafana you
   used is not where KrakenD runs, say that what you noticed in the data is from that
   environment.
2. **What it shows**: one line per section. Then what you noticed in their data
   (for example, "/legacy is timing out: p95 1.47s against a 1s timeout").
3. **Waiting for data**: panels that fill in after their first event, in one line
   ("Errors, timeouts and breaker panels fill in when the first one happens").
   In config-only mode, replace this with one line: built from the config, and empty until this
   Grafana's Prometheus scrapes that gateway (or import the JSON file where it is scraped).
4. **Get more metrics** (always include it when there are relevant gaps or unavailable recipes;
   put it before the defaults): for each, in order of value for this dashboard:
   what it would add in plain words → the option → the snippet (merged into their real config
   path, e.g. `extra_config.telemetry/opentelemetry.layers.backend.metrics`). Note the cost
   if there is one (e.g. `detailed_connection` adds series per backend). Then offer to apply them:
   "Want me to add these to krakend.json and validate it?" Never edit their config without a
   yes; when they say yes, edit it, run `validate_config`, and remind them KrakenD needs a restart.
5. **Choices you made**: defaults, and anything you left out with the reason, as a question if it
   depends on them (where KrakenD runs, which nodes...).

Leave out how the tools behaved: workarounds, unexpected tool output, catalog/name differences
that didn't change a panel, internal recipe ids. If a tool result was wrong and you worked around
it, mention it only if it changes what the user sees, in one line, in user terms.

## Editing an existing dashboard

`get_dashboard_by_uid` → change the JSON (keep panel ids stable, append new ids) → lint →
verify the new queries → `update_dashboard` with a message. Don't rebuild what the user didn't
ask to change.

## Guardrails

- Only touch dashboards tagged `generated-by-claude` unless the user explicitly names another one.
- Never delete dashboards or folders. Never change datasources.
- Don't put secrets or tokens in dashboard JSON or in the local file.
