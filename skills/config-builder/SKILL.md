---
name: config-builder
description: Creates new KrakenD configurations with best practices, proper structure, and edition-appropriate features
---

# KrakenD Configuration Builder

## Purpose
Guides users through creating new KrakenD configurations with best practices, proper structure, and edition-appropriate features. Provides interactive creation with validation at each step.

## When to activate
- User asks to create a new KrakenD configuration
- User mentions "new config", "create krakend", "setup api gateway", "build config"
- User wants to add endpoints to existing config
- User needs help structuring their KrakenD setup

## What this skill does

1. **Gathers requirements** through targeted questions
2. **Generates configuration** using templates and best practices
3. **Validates as you build** to prevent errors early
4. **Suggests optimizations** based on use case
5. **Spawns config-architect agent** for complex multi-service scenarios

## Decision tree

**Simple scenario** (1-3 endpoints, straightforward routing):
- Handle directly with generation tools
- Use `generate_endpoint_config` and `generate_basic_config`

**Complex scenario** (>3 endpoints, advanced features, microservices):
- Spawn `config-architect` agent
- Agent will design complete architecture

## Tools used
- `generate_basic_config` - Create complete configuration
- `generate_endpoint_config` - Create individual endpoints
- `generate_backend_config` - Create backend configurations
- `get_feature_config_template` - Get templates for specific features
- `list_features` - Browse available features and check edition requirements
- `check_edition_compatibility` - Verify if config requires CE or EE
- `validate_config` - Validate generated configuration
- `search_documentation` - Find relevant examples

## Workflow

### Step 1: Understand requirements
Ask user:
- What endpoints do they need? (paths and methods)
- What are the backend services? (URLs)
- Do they need authentication? (JWT, API keys, etc.)
- Do they need rate limiting?
- Are they using Community or Enterprise Edition?

### Step 2: Generate configuration
Use generation tools to create config:
```
1. Start with basic structure (generate_basic_config)
2. Add endpoints one by one (generate_endpoint_config)
3. Add features as needed (get_feature_config_template)
4. Validate after each addition (validate_config)
```

### Step 3: Apply best practices
Always include:
- ✅ Circuit breakers for reliability
- ✅ Timeouts to prevent hanging
- ✅ Rate limiting for protection
- ✅ Authentication for sensitive endpoints
- ✅ Proper error handling

### Step 4: Validate and present
- Run `validate_config` on final result
- Present configuration with explanations
- Highlight any warnings or best practices
- Offer to save to file

## Output format

```
# KrakenD Configuration Created

I've created a KrakenD configuration for you:

## Summary
- Port: 8080
- Endpoints: 3
- Features: JWT validation, rate limiting, circuit breakers
- Edition: Community Edition compatible

## Configuration

\`\`\`json
{
  "version": 3,
  "$schema": "https://www.krakend.io/schema/krakend.json",
  "port": 8080,
  "timeout": "3000ms",
  "endpoints": [
    ...
  ]
}
\`\`\`

## Features Included

### Authentication (JWT)
- Validates tokens from your identity provider
- **Location**: endpoints[0].extra_config["auth/validator"]
- **Docs**: https://www.krakend.io/docs/authorization/jwt-validation/

### Rate Limiting
- Protects endpoints from overload
- **Config**: 100 requests/second per endpoint
- **Docs**: https://www.krakend.io/docs/endpoints/rate-limit/

### Circuit Breakers
- Prevents cascade failures
- **Config**: Opens after 5 errors in 60 seconds
- **Docs**: https://www.krakend.io/docs/backends/circuit-breaker/

## Next Steps

1. **Save this configuration** to `krakend.json`
2. **Test it**: `krakend check -c krakend.json`
3. **Run it**: `krakend run -c krakend.json`
4. **Monitor**: Check logs at startup

Would you like me to:
- Add more endpoints?
- Add additional features (caching, CORS, etc.)?
- Optimize for specific use case?
- Explain any part in detail?
```

## Best practices

1. **Ask before assuming** - Don't guess backend URLs or requirements
2. **Validate edition compatibility** - Check if requested features need EE
3. **Always include safety features** - Circuit breakers, timeouts, rate limits
4. **Explain what you're adding** - Don't just dump JSON, explain each part
5. **Offer alternatives** - If they request EE feature but have CE, suggest alternatives
6. **Validate before presenting** - Never show invalid configurations

## Examples

### Example 1: Simple REST API Gateway

**User**: "Create a config for my REST API at https://api.example.com"

**Response:**
"I'll create a KrakenD configuration for your REST API. Let me ask a few questions:

1. What endpoints do you want to expose? (e.g., GET /users, POST /users)
2. Do you need authentication? (JWT, API keys, or none)
3. Should I add rate limiting?

Or should I create a basic setup and you can tell me what to adjust?"

[User provides answers]

[Generate configuration using tools]

[Present as shown in output format above]

### Example 2: Complex Microservices Gateway

**User**: "I need a gateway for my microservices: user-service, order-service, payment-service, and inventory-service. Each has multiple endpoints."

**Response:**
"This sounds like a complex microservices architecture. I'm going to spawn the config-architect agent to design this properly. The agent will:

1. Map out all your services and endpoints
2. Design the aggregation strategy
3. Configure proper isolation (circuit breakers per service)
4. Set up authentication and rate limiting
5. Optimize for performance

One moment while I analyze your requirements..."

[Spawn config-architect agent]

### Example 3: Adding features to existing config

**User**: "Add JWT validation to my existing config"

**Response:**
"I'll add JWT validation to your configuration. I need a few details:

1. **Algorithm**: Which algorithm does your JWT use? (RS256, HS256, etc.)
2. **JWK URL**: Where can KrakenD fetch your public keys?
3. **Audience**: What audience value should KrakenD expect?

Also, which endpoints need JWT validation? (all, or specific ones?)"

[User provides details]

[Use `get_feature_config_template` for JWT]

[Merge into existing config]

[Validate with `validate_config`]

[Present updated configuration]

## When to spawn config-architect agent

Spawn the agent when:
- **More than 3 services** with multiple endpoints each
- **Complex aggregation** needed (combining multiple backends)
- **Advanced patterns** requested (sequential calls, conditional routing)
- **User explicitly asks** for architectural guidance
- **Microservices architecture** mentioned

## Error handling

- If user's backend URLs are unreachable: Note this, proceed with config anyway
- If requested feature requires EE but user has CE: Explain and offer alternatives
- If requirements are unclear: Ask specific questions, don't guess
- If configuration becomes too complex: Suggest splitting into multiple configs

## Integration with other skills

- After creating config → Offer to validate with `config-validator` skill
- If user asks "what features are available" → Hand off to `feature-explorer` skill
- If config already exists and user wants changes → Treat as modification, not new creation

## Tips for great configs

1. **Start small** - Basic config first, add features incrementally
2. **Explain defaults** - Tell user why you chose specific timeout, rate limit, etc.
3. **Think about production** - Include monitoring, logging, error handling
4. **Edition awareness** - Always check CE vs EE
5. **Link to docs** - Help user learn, don't just generate config
