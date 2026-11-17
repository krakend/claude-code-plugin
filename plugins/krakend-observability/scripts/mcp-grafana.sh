#!/usr/bin/env bash
# Starts the Grafana MCP server (grafana/mcp-grafana) in Docker over stdio.
#
# Users enter the Grafana URL they open in their browser. A container can't reach the host's
# localhost, so localhost / 127.0.0.1 / [::1] are mapped to host.docker.internal (with the
# host-gateway mapping that Linux needs). Any other URL is used as-is.
#
# GRAFANA_URL and GRAFANA_SERVICE_ACCOUNT_TOKEN come from the plugin's userConfig (.mcp.json env).
set -euo pipefail

IMAGE="grafana/mcp-grafana:2.2.0"

if ! command -v docker >/dev/null 2>&1; then
  echo "krakend-observability: Docker is required to run the Grafana MCP server" >&2
  exit 1
fi

url="${GRAFANA_URL:-}"
if [[ -z "$url" ]]; then
  echo "krakend-observability: Grafana URL is not configured (plugin settings)" >&2
  exit 1
fi
url="$(printf '%s' "$url" | sed -E 's#^(https?://)(localhost|127\.0\.0\.1|\[::1\])([:/]|$)#\1host.docker.internal\3#')"

export GRAFANA_URL="$url"
exec docker run --rm -i \
  --add-host=host.docker.internal:host-gateway \
  -e GRAFANA_URL \
  -e GRAFANA_SERVICE_ACCOUNT_TOKEN \
  "$IMAGE" \
  -t stdio \
  --enabled-tools search,datasource,prometheus,dashboard,folder,navigation,annotations,rendering \
  --usage-stats disabled
