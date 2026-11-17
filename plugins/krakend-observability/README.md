# KrakenD Observability (Claude Code plugin)

Generate and edit Grafana dashboards for KrakenD from plain language:

> "Build me an overview dashboard for this gateway"
> "Why is /orders slow? Show me where the time goes"
> "Add a panel with circuit breaker openings per backend"

Claude reads your KrakenD config to know which metrics it produces, checks what your Prometheus
already has, builds the dashboard from tested PromQL, lints and runs the queries, pushes it to
Grafana and renders it to check the result. It also tells you which config options would give
you more metrics, and offers to add them.

Dashboards are portable: you can build them against a local or staging Grafana (even one with no
KrakenD data yet, straight from the config) and import the saved JSON into production.

## What's inside

| Component | What it does |
|---|---|
| `grafana` MCP server | Official [grafana/mcp-grafana](https://github.com/grafana/mcp-grafana) (pinned 2.2.0), run with Docker. Reads datasources, runs PromQL, creates and updates dashboards, renders panels. |
| `krakend-dashboards` skill | The workflow: dashboard conventions (layout, units, portability), a layout script and a dashboard skeleton. |
| Dependency: `krakend-ai-assistant` | KrakenD MCP server, which holds the KrakenD knowledge: metrics catalog, config analysis, tested PromQL recipes and topic layouts, and the dashboard linter (plus docs and config validation). Needs a version with the observability tools. Installed from the same marketplace. |

## Requirements

- **Docker** installed and running. The Grafana MCP server runs as a container.
- **Grafana 9+** (OSS, Enterprise or Cloud) with a Prometheus-compatible datasource that scrapes KrakenD.
- A Grafana **service account token with the Editor role**.
- **KrakenD with OpenTelemetry metrics** going to Prometheus (`telemetry/opentelemetry` with a
  `prometheus` exporter, or OTLP to a collector that ends in Prometheus/Mimir). For backend
  detail, enable `layers.backend.metrics.round_trip`, `read_payload` and `detailed_connection`.
- `python3` (the layout script uses only the standard library).

## Setup

1. Install the plugin:

   ```bash
   /plugin marketplace add krakend/claude-code-plugin
   /plugin install krakend-observability@krakend
   ```

   `krakend-ai-assistant` is installed with it as a dependency. Claude Code asks for:
   - **Grafana URL**, as you open it in the browser (`http://localhost:3000`, `https://grafana.example.com`, Grafana Cloud). Local URLs are mapped for the Docker container automatically.
   - **Service account token** (stored in your system keychain, not in settings files).
2. Restart Claude Code or run `/reload-plugins`. Check with `/mcp` that `grafana` is connected.
3. Ask for a dashboard.

Change the values later in `/config` (URL) or by reconfiguring the plugin (token).

## Conventions

Dashboards are created in the `KrakenD` folder with uid `krakend-ai-*` and tags
`krakend, generated-by-claude`. A copy of the JSON is saved in your working directory so you can
version it. Claude only edits dashboards carrying the `generated-by-claude` tag unless you name
another one, and never deletes dashboards or changes datasources.

## Naming conventions

Both KrakenD metric naming conventions are supported: the default one, and OpenTelemetry semantic
convention 1.27 (`layers.global.semantic_convention: "1.27"`). Claude detects which one your
Prometheus has and converts the dashboard queries accordingly.

## Known limits

- Prometheus/PromQL only. Datadog, New Relic, InfluxDB etc. aren't supported yet.
- The metrics catalog is generated from a KrakenD EE build (see `krakend_version` in the catalog). Other versions may differ. Claude always
  checks live metric names first and tells you when they differ from the catalog.
- There is no dedicated rate-limit metric. Rate-limit rejections are inferred from status codes on
  rate-limited endpoints.
