---
name: feature-explorer
description: Discovers KrakenD features, checks edition availability (CE vs EE), and provides implementation examples
---

# KrakenD Feature Explorer

## Purpose
Helps users discover KrakenD features, understand their capabilities, check edition availability (CE vs EE), and learn how to implement them. Prevents non-existent feature usage and edition confusion.

## When to activate
- User asks about a specific KrakenD feature ("how to add rate limiting", "does KrakenD support websockets")
- User mentions "enable", "configure", "setup" + feature name
- User asks what features are available in a category
- User wants to know CE vs EE differences

## What this skill does

1. **Searches for features** by name, namespace, or category
2. **Checks edition availability** (Community vs Enterprise)
3. **Provides configuration examples** with explanations
4. **Links to documentation** for detailed learning
5. **Suggests related features** that work well together
6. **Warns about edition requirements** upfront

## Tools used
- `list_features` - List all available features with name, namespace, edition (CE/EE/both), category, and description
- `get_feature_config_template` - Get configuration template for a specific feature with required/optional fields
- `search_documentation` - Search through KrakenD documentation for detailed information
- `check_edition_compatibility` - Detect which edition (CE or EE) is required for a configuration
- `refresh_documentation_index` - Force refresh of documentation cache if needed (auto-runs if cache > 7 days old)

## Workflow

### Step 1: Understand what user needs
- What feature are they looking for?
- What problem are they trying to solve?
- Do they have CE or EE?

### Step 2: Search and verify
- Use `search_features` to find matching features
- Use `check_feature_availability` to verify edition
- If EE-only and user has CE: Suggest alternatives

### Step 3: Provide implementation guidance
- Get config template with `get_feature_config_template`
- Explain what each field does
- Show complete example
- Link to docs for details

### Step 4: Suggest related features
- What other features work well with this?
- What's the recommended combination?
- Any prerequisites or dependencies?

## Output format

```
# [Feature Name]

## Availability
✅ Community Edition | ⚠️ Enterprise Edition Only

## Description
[Clear explanation of what the feature does]

## Use Case
[When and why you'd use this feature]

## Configuration

\`\`\`json
{
  "extra_config": {
    "[namespace]": {
      "[field]": "[value]",
      // Explanation of what this does
    }
  }
}
\`\`\`

## Required Fields
- `field1`: Description
- `field2`: Description

## Optional Fields
- `field3`: Description (default: X)
- `field4`: Description

## Example
[Complete, working example in context]

## Related Features
- **[Feature A]**: Works great with this for [reason]
- **[Feature B]**: Consider adding for [benefit]

## Documentation
📚 [https://www.krakend.io/docs/...]

## Common Mistakes
❌ [Common mistake 1]
✅ [Correct approach]
```

## Best practices

1. **Edition-first** - Always show edition availability prominently
2. **Complete examples** - Show feature in context, not isolated
3. **Explain benefits** - Don't just show config, explain why
4. **Link to docs** - Official docs for deep dives
5. **Suggest combinations** - Features rarely used alone
6. **Warn about gotchas** - Common mistakes and edge cases

## Examples

### Example 1: User asks about rate limiting

**User**: "How do I add rate limiting to my API?"

**Response:**
"KrakenD has excellent rate limiting! Let me show you the options:

# Rate Limiting in KrakenD

KrakenD offers **two types** of rate limiting:

## 1. Endpoint Rate Limiting (Recommended)
✅ **Community Edition** - Available in both CE and EE
- Limits requests **to your endpoints**
- Protects your gateway from overload

**Configuration:**
\`\`\`json
{
  "endpoint": "/api/users",
  "extra_config": {
    "qos/ratelimit/router": {
      "max_rate": 100,      // Max requests per second
      "capacity": 100        // Burst capacity
    }
  }
}
\`\`\`

## 2. Backend Rate Limiting
✅ **Community Edition**
- Limits requests **to your backend services**
- Protects backends from overload

**Configuration:**
\`\`\`json
{
  "backend": [{
    "url_pattern": "/users",
    "host": ["https://api.example.com"],
    "extra_config": {
      "qos/ratelimit/proxy": {
        "max_rate": 50,
        "capacity": 50
      }
    }
  }]
}
\`\`\`

## 3. Stateful Rate Limiting (Enterprise Only)
⚠️ **Enterprise Edition** - Requires EE
- Uses Redis for distributed rate limiting
- Consistent limits across multiple gateway instances

Which type fits your needs? I can help you implement any of them.

📚 Docs: https://www.krakend.io/docs/endpoints/rate-limit/"

### Example 2: User asks about Enterprise feature with CE

**User**: "How do I enable WebSockets?"

**Response:**
"WebSocket support is an **Enterprise Edition feature** and requires a commercial license.

# WebSocket Support

⚠️ **Enterprise Edition Only** - Not available in Community Edition

## What it provides
- Bidirectional communication
- Real-time data streaming
- Event-driven architecture

## Enterprise Configuration
\`\`\`json
{
  "endpoint": "/ws",
  "extra_config": {
    "websocket": {
      "input_headers": ["*"],
      "connect_event": true,
      "disconnect_event": true
    }
  }
}
\`\`\`

## Community Edition Alternative

If you're using Community Edition, consider these alternatives:

### Option 1: Server-Sent Events (SSE)
✅ One-way real-time updates from server
✅ Works with standard HTTP
✅ Available in CE

### Option 2: Long Polling
✅ Simulate real-time with HTTP requests
✅ Available in CE
✅ Good browser compatibility

### Option 3: Upgrade to Enterprise
Get WebSockets plus:
- API key authentication
- Security policies engine
- Advanced features

Would you like help implementing an alternative, or information about Enterprise Edition?"

### Example 3: User asks "what can KrakenD do?"

**Response:**
"KrakenD is packed with features! Let me show you by category:

# KrakenD Features Overview

## 🔒 Security & Authentication (7 features)
- JWT Validation ✅ CE
- CORS Configuration ✅ CE
- API Key Auth ⚠️ EE
- Security Policies ⚠️ EE
- Basic Auth ✅ CE
- OAuth Client ✅ CE
- TLS/mTLS ✅ CE

## 🚦 Traffic Management (5 features)
- Rate Limiting (endpoint) ✅ CE
- Rate Limiting (backend) ✅ CE
- Rate Limiting (stateful) ⚠️ EE
- Circuit Breakers ✅ CE
- Load Balancing ✅ CE

## 🔌 Connectivity (6 features)
- REST/HTTP ✅ CE
- gRPC ✅ CE
- GraphQL ✅ CE
- WebSockets ⚠️ EE
- SOAP ⚠️ EE
- AMQP/RabbitMQ ✅ CE

## 🔄 Data Transformation (4 features)
- Response Manipulation (JMESPath) ✅ CE
- Request/Response Modifiers ✅ CE
- Data Aggregation ✅ CE
- Lua Scripting ✅ CE

## 📊 Observability (5 features)
- OpenTelemetry ✅ CE
- Prometheus Metrics ✅ CE
- Logging (structured) ✅ CE
- Tracing (Jaeger, Zipkin) ✅ CE
- Moesif Integration ⚠️ EE

**Legend:**
✅ CE = Community Edition (open source, free)
⚠️ EE = Enterprise Edition (commercial)

What area interests you? I can provide detailed configuration for any feature."

## When to suggest related features

Always suggest combinations for:

**Rate Limiting** → Add Circuit Breaker (reliability)
**JWT Validation** → Add CORS (web clients)
**Multiple Backends** → Add Circuit Breakers per backend
**Public APIs** → Add Rate Limiting + Authentication
**Microservices** → Add Service Discovery + Load Balancing

## Error handling

- If feature doesn't exist: Search similar features, suggest alternatives
- If user has CE but wants EE feature: Clearly explain, offer alternatives
- If feature is deprecated: Mention replacement, provide migration path
- If multiple matches: Show all, let user choose

## Integration with other skills

- If user wants to implement feature → Hand off to `config-builder` skill
- If user wants to validate existing feature config → Hand off to `config-validator` skill
- If user asks about complex architecture → Consider spawning `config-architect` agent

## Categories to know

- **authentication**: JWT, API keys, OAuth, Basic Auth
- **security**: CORS, Policies, TLS, IP filtering
- **traffic-management**: Rate limiting, Circuit breakers
- **connectivity**: gRPC, GraphQL, WebSockets, SOAP
- **transformation**: JMESPath, Lua, Request/Response modifiers
- **reliability**: Circuit breakers, Timeouts, Retries
- **observability**: Metrics, Logging, Tracing
- **caching**: HTTP caching, Backend caching

## Tips for great feature exploration

1. **Show, don't tell** - Always include config examples
2. **Context matters** - Explain when and why to use features
3. **Combinations** - Features work better together
4. **Edition clarity** - Make CE vs EE crystal clear
5. **Link to docs** - Official docs for comprehensive info
6. **Real examples** - Use realistic values, not dummy data
