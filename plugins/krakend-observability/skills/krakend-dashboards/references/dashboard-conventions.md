# KrakenD dashboard conventions

Every dashboard this skill produces follows these rules, so dashboards from different prompts
look like one product and can be edited later by another prompt.

## Identity

- `uid`: `krakend-ai-<kebab-slug>` (max 40 chars). Reuse the same uid when the user asks to
  change a dashboard. Never create a near-duplicate.
- `title`: human title, no "KrakenD -" prefix (the folder already says it).
- `tags`: always `["krakend", "generated-by-claude"]` plus 1-3 topical tags (`latency`, `backends`,
  `errors`, `resilience`, `runtime`, `demo`).
- Folder: `KrakenD` (create it if missing). Only use another folder if the user asks.
- `description`: one sentence with the user's original request, so the dashboard explains itself.
- `refresh`: `30s` for live views, `""` for analysis dashboards. `time`: `now-1h` unless asked.

## Variables (templating)

Start from `assets/dashboard-skeleton.json`, which defines these. Remove the ones a dashboard
doesn't use, and never invent others without a reason.

| name | type | definition | notes |
|---|---|---|---|
| `datasource` | datasource | `prometheus` | every panel and target uses `{"type":"prometheus","uid":"${datasource}"}` |
| `job` | query | `label_values(http_server_duration_count, job)` | multi, include All, **no allValue** |
| `instance` | query | `label_values(http_server_duration_count{job=~"$job"}, instance)` | multi, include All, **no allValue** |
| `endpoint` | query | `label_values(http_server_duration_count{job=~"$job", http_route!="404 Not Found"}, http_route)` | multi, include All, allValue `.*` |
| `backend_host` | query | `label_values(http_client_duration_count{job=~"$job"}, server_address)` | only if http_client_* exists |

`job` and `instance` have no `allValue`: "All" then expands to the KrakenD jobs and instances
found, so queries on shared metrics (`up`, `process_*`, `go_*`) don't pick up other targets of a
shared Prometheus. `endpoint` and `backend_host` keep `allValue: ".*"`.

If production scrapes KrakenD with an `app` label (the official KrakenD dashboards use it), you
may add an `app` variable. The dev Prometheus having it is a hint, not proof: ask if the dashboard
is meant for another environment, and never assume it (see Portability).

## Layout

- Grid is 24 columns wide. Row 1 is KPI stats (h=4, w=4 or 6): RPS, 5xx ratio, p95, nodes up.
- Then timeseries panels (h=8, w=12 two per row, or w=24 for the main chart).
- Group sections with `row` panels: Overview, Endpoints, Backends, Resilience, Runtime.
- Order matters: what the user asked about goes first, context after.
- Max ~16 panels for a question ("why is /orders slow"). A dashboard about a topic follows its
  blueprint and can have 25-35 panels.

## Dashboards about one topic

When the user asks for a dashboard *about* a topic ("runtime dashboard", "backends dashboard"),
it is the main subject, not context: build all of it, following the structure of KrakenD's
official dashboards (github.com/krakend/telemetry-dashboards). A stat row answers "how is it
right now", then rows of time series answer "how did it change".

The rows for `overview`, `runtime`, `backends` and `agents` come from `get_dashboard_recipes`
(`blueprints[<intent>]`), already filtered to what the config enables: use them in that order.
For `websocket`, `kafka`, `redis` and `ai`, use every recipe of the intent, stats first, client
and backend side (or publish and consume) in separate rows.

## Panels that depend on where KrakenD runs

The machine you can query is often a developer laptop; the dashboard is usually for staging or
production. Never drop a panel only because this environment can't produce it:
- `runtime.network_io` is Linux-only (empty on macOS/Windows, always present in Linux containers).
- `runtime.memory_limit_usage` needs `GOMEMLIMIT`.
- Backends, brokers, LLM providers or Redis that are down or unreachable locally.

Keep these panels with a description saying when they fill in. If it matters and you can't tell
where the dashboard will be used (e.g. KrakenD runs on macOS here), ask the user once, together
with any other question, e.g. "Will this dashboard watch KrakenD on Linux (containers/servers)?
Then I'll keep the network I/O panel, which is empty on this Mac." Never decide silently.

## Panels

- Units: `reqps`, `percentunit`, `s`, `bytes`, `Bps`, `short`. Set `fieldConfig.defaults.unit`
  on every panel.
- Error ratio stats: thresholds green < 0.01, orange < 0.05, red (4xx: 0.05 / 0.20, since auth and
  validation rejections are normal). Latency stats: thresholds from the user's SLO if given, else
  green < 0.3s, orange < 1s, red. Recipes from `get_dashboard_recipes` with `grafana_panel` already
  have these thresholds and the status-class colors; adjust them only to the user's SLO.
- Legends: `{{http_route}}`, `{{server_address}}`, `{{http_response_status_code}}`. Never leave the
  default `__auto` legend for multi-series panels.
- Every panel gets a one-line `description` with what it shows and which recipe id it came from,
  e.g. `p95 client latency per endpoint (recipe latency.p95_by_endpoint)`.
- Status code panels: fixed colors by class (`2..` green, `4..` orange, `5..` red) using overrides by
  regex on the series name, plus distinct shades for common codes (404 light orange, 429 purple,
  503 dark red...) so codes of the same class stacked together stay apart. Recipe panels have them.
- Use `$__rate_interval` in rate/increase for timeseries. Use `$__range` for stats/tables that
  summarise the selected period.
- Tables from instant queries: set `"instant": true, "format": "table"` and add an `organize`
  transformation to hide `Time`.

## Panels waiting for their first event

Build panels from the config, not only from current data. A gateway without errors yet still
needs its error panels. Queries return 0 when that's correct (`or vector(0)` on stats,
`or 0 * <traffic>` per series); otherwise leave Grafana's plain "No data".

Panels never carry anything about data or testing status: no `noValue` texts ("none yet",
"waiting for..."), no "no data until..." or "not verified" in titles or descriptions. Which
panels are still empty goes in your reply only.

## Keep the JSON compact

`update_dashboard` takes the whole dashboard inline, so size matters on 30-50 panel dashboards:
set the datasource once per panel (not per target), and leave out options that only restate
Grafana's defaults (legend, tooltip, draw style). Recipe panels are already written this way.

## Portability

Dashboards are built wherever the user has a Grafana (often dev/local) and imported into
production Grafanas. The JSON must work there unchanged:
- Datasource only through the `${datasource}` variable (type `datasource`, `current: {}`). Never a
  datasource uid or name.
- Scrape labels (`job`, `instance`, hosts and ports) only through `=~"$var"` matchers. Never a
  literal value seen in the dev Prometheus (`instance="localhost:8080"`, `job="krakend"`).
- Variables start at "All" (`current: {"text": "All", "value": "$__all"}`). When you edit a
  dashboard fetched from Grafana, reset the `current` values Grafana saved.
- `app` and other optional labels: add a variable only if the user says production has them
  (or the official KrakenD dashboards' setup is in use), not just because the dev scrape does.
- Values that come from the KrakenD config are portable: endpoint routes, backend url patterns,
  circuit breaker names, LLM models, topics. Panels pinned to one endpoint use those.
- Thresholds come from conventions or the user's SLO, never from what dev traffic looks like.
- Keep panels the dev machine can't fill (Linux-only process metrics, `GOMEMLIMIT`).

## Things to avoid

- High-cardinality legends (`instance` x `http_route` x `status`) on one panel. Pick one dimension
  or use `topk`.
- Mixing global-layer `http_route` (endpoint) with backend-layer `http_route` (backend path) in the
  same `by()` without renaming. They mean different things.
- `rate()` on gauges (`krakend_cb_errors_*`, `go_goroutines`).
- `${var:regex}` formatting in PromQL. It emits `\-`, which Prometheus rejects. Plain `$var` in
  `=~"$var"` is already escaped correctly by Grafana.
- Averaging percentiles across instances. Aggregate buckets first: `sum by (le)`.
