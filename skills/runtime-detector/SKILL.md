---
name: runtime-detector
description: Detects the optimal way to run KrakenD (native binary vs Docker) and provides correct execution commands
license: Apache-2.0
compatibility: Requires KrakenD MCP Server
metadata:
  author: krakend
---

# Runtime Detector

## Purpose
Determines the correct way to execute KrakenD commands by detecting available runtimes and providing ready-to-use commands with the appropriate Docker image or native binary.

## When to activate
- User asks to run/start/execute KrakenD: "run krakend", "start the gateway", "execute krakend"
- User mentions Docker commands for KrakenD: "docker run krakend", "which docker image"
- User asks how to run their config: "how do I run this", "start my config"
- User asks about KrakenD versions or images: "which version", "what image to use"

## CRITICAL: Always Use Runtime Detection

**NEVER invent Docker images or commands.** Always follow this process:

1. Call `detect_runtime_environment` tool with the config file path
2. Use the `recommendations` array from the response (ordered by priority)
3. Use `command_template` from priority=1 recommendation
4. If Docker needed, use `recommended_image` field for the image name

**Common hallucinations to avoid:**
- ❌ `devopsfaith/krakend` (outdated)
- ❌ `krakend:latest` without checking
- ❌ `krakend/krakend:version` (wrong format)
- ✅ Use exactly what `detect_runtime_environment` returns

## What the tool returns
- `has_native_krakend`: Whether native binary is installed
- `has_docker`: Whether Docker is available
- `recommended_image`: Correct Docker image (e.g., `krakend:2.8` or `krakend/krakend-ee:2.8`)
- `recommendations`: Array of execution options with `command_template` ready to use
- `is_enterprise`: Whether config uses EE features

## Example Interaction
**User:** "Run my krakend.json"
**Response:** Call `detect_runtime_environment`, then provide the command from `command_template`. Explain if using native or Docker and why.

## Integration
- After `config-validator` validates successfully → Offer to run with this skill
- After `config-builder` creates config → Offer to test run
- If user needs to validate first → Hand off to `config-validator`
