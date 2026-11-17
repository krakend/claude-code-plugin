---
name: config-validator
description: Validates KrakenD configurations with specific error fixes, edition compatibility checks, anti-pattern detection, and Flexible Configuration support
license: Apache-2.0
compatibility: Requires KrakenD MCP Server and Docker or native KrakenD binary for validation
metadata:
  author: krakend
---

# KrakenD Configuration Validator

## Purpose
Validates KrakenD configurations with specific error fixes, edition compatibility checks, anti-pattern detection, and automatic Flexible Configuration support with actionable feedback.

## When to activate
- User asks to validate a KrakenD configuration
- User mentions "check config", "validate krakend", "is this valid", "config errors"
- User has JSON syntax errors in krakend.json
- User wants to verify CE vs EE compatibility

## What this skill does
Validates JSON syntax with specific line/column error reporting, checks edition compatibility (CE vs EE features), detects configuration issues using smart three-tier validation (native → Docker → schema), auto-detects Flexible Configuration (CE and EE variants), and provides specific fixes with exact locations and documentation links.

## CRITICAL: Anti-Hallucination Rules

**YOU MUST FOLLOW THESE RULES - NO EXCEPTIONS:**

✅ **DO:**
- Only fix errors explicitly listed in validation output
- Read the `guidance` field in every validation result (contains binding instructions)
- Search KrakenD documentation when uncertain about syntax
- Trust validation output as authoritative

❌ **DON'T:**
- Suggest fixes based on assumptions, patterns, or intuition
- Add corrections that aren't in the error list
- Guess syntax based on patterns from other systems
- Add fields that "should be there" without validation saying so

**Example:**
- ❌ WRONG: Validation says "unknown field: 'backend'" → You suggest "backends" (hallucination)
- ✅ CORRECT: Validation says "missing field 'timeout'" → You suggest adding timeout

## KrakenD-Specific Quirks
**Flexible Configuration:** CE uses .tmpl files with Go templates (requires FC_ENABLE=1, FC_SETTINGS env vars). EE uses flexible_config.json (auto-detected, no env vars). Skill auto-detects FC variant and adjusts validation commands automatically.
**Schema:** Always use versionless `https://www.krakend.io/schema/krakend.json`
**Docker/Edition:** CE uses `krakend` image, EE uses `krakend/krakend-ee` image (requires LICENSE file)
**Validation Tiers:** Native `krakend check` (most accurate) > Docker > JSON Schema

## Dynamic Sources
- **Documentation:** Search KrakenD documentation to verify syntax when uncertain
- **Edition Compatibility:** Check edition requirements (CE vs EE) or browse https://www.krakend.io/features/
- **Runtime Detection:** ALWAYS call `detect_runtime_environment` tool BEFORE running any KrakenD command. Use its `command_template` and `recommended_image` fields - NEVER invent Docker images or commands.
- **KrakenD MCP Tools:** Use the available tools for validation, edition checking, and documentation search. Always read the `guidance` field in validation results.

## Example Interaction
**User:** "Validate my krakend.json"
**Response pattern:** Detect runtime environment, run validation, read `guidance` field from results, report errors with exact locations, suggest fixes ONLY for errors listed (never assume), offer to re-validate after fixes.

## Edge Cases
- **Flexible Configuration detected:** Auto-detect CE (.tmpl) or EE (flexible_config.json) variant, adjust validation
- **EE features in config:** Report which features require Enterprise Edition, explain their benefits - only suggest CE workarounds if user asks
- **Validation tool unavailable:** Fall back through tiers (native → Docker → schema), inform user of method

## Integration
- Create new config → Hand off to `config-builder` skill
- "How to add X" → Hand off to `feature-explorer` skill
- Validation passes but user wants security audit → Hand off to `security-auditor` skill
- Validation passes and user wants to run KrakenD → Hand off to `runtime-detector` skill
