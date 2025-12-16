# Config Architect Agent

## Purpose
Designs complete KrakenD architectures for complex multi-service scenarios. Spawned by the `config-builder` skill when the user's requirements are too complex for simple generation.

## When spawned
- More than 3 backend services with multiple endpoints each
- Complex aggregation patterns (combining multiple backends)
- Advanced routing requirements (conditional, sequential)
- Microservices architecture design
- User explicitly asks for architectural guidance

## What this agent does

This agent takes a holistic approach to designing your KrakenD configuration:

1. **Analyzes requirements** - Understands your services, endpoints, and relationships
2. **Designs architecture** - Plans the optimal structure for your use case
3. **Configures isolation** - Sets up proper circuit breakers per service
4. **Implements patterns** - Applies best practices for microservices gateways
5. **Validates design** - Ensures the architecture will work correctly
6. **Documents decisions** - Explains why each choice was made
7. **Provides deployment guide** - Shows how to test and run the configuration

## Architecture Patterns Supported

### Pattern 1: Simple Aggregation
**When:** Multiple backends, single endpoint, combine responses
**Use case:** Frontend needs data from multiple services
**Example:** `/dashboard` aggregates user + orders + notifications

### Pattern 2: Service-per-Endpoint
**When:** Each endpoint maps to one service
**Use case:** Traditional microservices gateway
**Example:** `/users/*` → user-service, `/orders/*` → order-service

### Pattern 3: Sequential Processing
**When:** Backend calls happen in order, output of one feeds next
**Use case:** Multi-step workflows
**Example:** Validate → Process → Notify

### Pattern 4: Conditional Routing
**When:** Route based on request data or headers
**Use case:** A/B testing, canary releases
**Example:** Route to v2 if header present, else v1

## Design Process

### Step 1: Service Discovery
Ask about each service:
- Service name and purpose
- Base URL and health endpoint
- Expected response time
- Criticality (can it fail?)
- Authentication requirements

### Step 2: Endpoint Mapping
For each endpoint user needs:
- Which services does it call?
- Should calls be parallel or sequential?
- How to combine responses?
- What error handling is needed?

### Step 3: Cross-Cutting Concerns
Apply to all services:
- Circuit breakers (different thresholds per service criticality)
- Rate limiting (endpoint-level protection)
- Authentication (JWT validation strategy)
- Observability (logging, metrics, tracing)

### Step 4: Optimization
- Minimize backend calls where possible
- Configure appropriate timeouts
- Add caching where beneficial
- Set up proper error responses

### Step 5: Validation & Documentation
- Validate complete configuration
- Document architecture decisions
- Provide appropriate deployment commands
- Include monitoring recommendations

## Tools used

**All generation tools:**
- `generate_basic_config` - Create base structure
- `generate_endpoint_config` - Create each endpoint
- `generate_backend_config` - Configure each backend
- `get_feature_config_template` - Add features

**All validation tools:**
- `validate_config` - Ensure configuration works
- `check_edition_compatibility` - Verify CE/EE compatibility

**All feature tools:**
- `list_features` - Find appropriate features
- `search_documentation` - Find best practices

## Output format

The agent produces a comprehensive architecture document with the working configuration:

```markdown
# KrakenD Architecture Design

## Overview
[High-level summary of the architecture]

## Services
1. **user-service** (Critical)
   - Base URL: https://users.example.com
   - Endpoints: 5
   - Circuit breaker: 3 errors in 30s

2. **order-service** (Critical)
   - Base URL: https://orders.example.com
   - Endpoints: 8
   - Circuit breaker: 5 errors in 60s

3. **notification-service** (Non-critical)
   - Base URL: https://notify.example.com
   - Endpoints: 2
   - Circuit breaker: 10 errors in 120s (lenient)

## Architecture Decisions

### Decision 1: Parallel Backend Calls
**Reason**: user-service and order-service are independent
**Benefit**: Faster response times (2x speedup)
**Implementation**: Default parallel execution in KrakenD

### Decision 2: Circuit Breaker Per Service
**Reason**: Isolate failures, protect healthy services
**Configuration**:
- Critical services: Stricter thresholds
- Non-critical: Lenient thresholds, failures don't block request

### Decision 3: JWT Validation at Gateway
**Reason**: Centralized auth, backends don't need to validate
**Implementation**: auth/validator on all authenticated endpoints

## Endpoint Design

### GET /api/dashboard
Aggregates data from 3 services:
- user-service: /profile
- order-service: /recent
- notification-service: /unread

**Pattern**: Parallel aggregation
**Response time**: ~500ms (max of all backends)
**Failure mode**: Returns partial data if non-critical service fails

### POST /api/orders
Sequential processing:
1. user-service: Validate user
2. order-service: Create order
3. notification-service: Send confirmation

**Pattern**: Sequential (must happen in order)
**Response time**: ~1.5s (sum of all backends)
**Failure mode**: Rollback on any failure

## Configuration

\`\`\`json
{
  "version": 3,
  "$schema": "https://www.krakend.io/schema/krakend.json",
  ...
}
\`\`\`

## Testing & Deployment

### Validate & Run Configuration
Provide commands based on: (1) Edition (CE/EE by features), (2) Version from `$schema`, (3) FC detection, (4) LICENSE for EE.

**Test:**
```bash
docker run --rm -v $(pwd):/etc/krakend krakend:VERSION check -tlc /etc/krakend/krakend.json
```

**Run:**
```bash
docker run --rm -p 8080:8080 -v $(pwd):/etc/krakend krakend:VERSION run -c /etc/krakend/krakend.json
```

**Flags:** Use `-tlc` (test + lint + config) for comprehensive validation.
**Images:** `krakend:VERSION` (CE) or `krakend/krakend-ee:VERSION` (EE).
**FC:** CE needs `FC_ENABLE=1` + env vars; EE auto-detects.

### Production Deployment
- Use environment variables for service URLs
- Enable telemetry (OpenTelemetry recommended)
- Set up health checks
- Configure log aggregation
- [Note about LICENSE file if EE features used]

## Monitoring Recommendations

1. **Circuit Breaker States**
   - Alert when any circuit opens
   - Dashboard showing open/closed state per service

2. **Response Times**
   - P50, P95, P99 per endpoint
   - Alert if P95 > 2s

3. **Error Rates**
   - Track 4xx vs 5xx errors
   - Alert if 5xx rate > 1%

## Testing Strategy

1. **Unit Tests**: Validate each endpoint independently
2. **Integration Tests**: Test with real backend services
3. **Load Tests**: Verify circuit breakers work under load
4. **Chaos Tests**: Kill backends, ensure graceful degradation

## Next Steps

1. ✅ Configuration is valid and ready to use
2. Test with development backends
3. Adjust circuit breaker thresholds based on real traffic
4. Set up monitoring dashboards
5. Plan gradual rollout

Questions or need adjustments?
```

## Best Practices

1. **Understand before designing** - Ask questions, don't assume requirements
2. **Consider failure modes** - What happens when services are down?
3. **Isolate critical from non-critical** - Different thresholds and handling
4. **Document decisions** - Explain the "why" not just the "what"
5. **Think about operations** - Monitoring, debugging, maintenance
6. **Validate thoroughly** - Catch errors before deployment
7. **Plan for scale** - Will this work with 10x traffic?
8. **Provide deployment commands** - Show exactly how to test and run
9. **Edition awareness** - Track CE vs EE features used

## Example Scenarios

### Scenario 1: E-commerce Platform
**Services**: users, products, cart, orders, payments, inventory
**Challenge**: Payment is critical, inventory is not
**Solution**:
- Strict circuit breakers for payment service
- Lenient circuit breakers for inventory (show cached data)
- Sequential processing for checkout
- Parallel loading for product pages

### Scenario 2: Social Media API
**Services**: posts, comments, likes, users, media
**Challenge**: High read traffic, eventual consistency OK
**Solution**:
- Aggressive caching (1-5 minutes)
- Parallel aggregation for feeds
- Rate limiting per user (prevent abuse)
- Media service has highest timeout (large files)

### Scenario 3: Internal Microservices
**Services**: 20+ internal services
**Challenge**: Complex dependencies, frequent changes
**Solution**:
- Group endpoints by service
- Use flexible configuration (templates + variables)
- Circuit breakers everywhere
- Central JWT validation
- Service discovery integration

## Integration with Skills

This agent is spawned by **config-builder** skill and returns control when done. The skill then:
1. Validates the architecture
2. Presents to user
3. Offers to save or adjust
4. Can re-spawn agent for modifications

## Error Handling

- **Services are unreachable**: Note in design, proceed with config
- **Requirements conflict**: Ask user to clarify priorities
- **Too complex even for agent**: Break into phases, design incrementally
- **Validation fails**: Debug, fix, re-validate before returning
- **Unclear edition**: Ask user which KrakenD edition they're using

## Tips for Great Architectures

1. **Start with services** - Understand what you're connecting first
2. **Map dependencies** - Who calls whom and when?
3. **Identify critical path** - What MUST work for the system to function?
4. **Plan for failure** - Everything fails eventually, design for resilience
5. **Keep it simple** - Don't over-engineer, start with basics
6. **Document well** - Future maintainers will thank you
7. **Think operationally** - How to debug? Monitor? Update?
8. **Test commands matter** - Always provide deployment-ready commands
