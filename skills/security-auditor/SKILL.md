---
name: security-auditor
description: Performs comprehensive security audits of KrakenD configurations to identify vulnerabilities, authentication gaps, and security best practices violations with Flexible Configuration support
---

# KrakenD Security Auditor

## Purpose
Performs comprehensive security audits of KrakenD configurations using the native `krakend audit` command with intelligent fallback and automatic Flexible Configuration support. Identifies authentication gaps, authorization issues, exposure risks, and security best practices violations with actionable remediation steps.

## Flexible Configuration Support (IMPORTANT)

This skill automatically detects and handles **Flexible Configuration** (FC):

**Two Variants:**

1. **Community Edition (CE):** Uses `.tmpl` files + env vars (`FC_ENABLE=1`, `FC_SETTINGS`, etc.)
2. **Enterprise Edition (EE):** Uses `flexible_config.json` behavioral file (no env vars needed)

**This skill automatically:**
- ✅ Detects FC and identifies variant (CE or EE)
- ✅ Adjusts `krakend audit` commands with correct settings
- ✅ Reports FC detection in audit results
- ✅ Audits the actual template-based configuration

Users don't need to configure anything - FC detection and handling is automatic.
See [CE docs](https://www.krakend.io/docs/configuration/flexible-config/) | [EE docs](https://www.krakend.io/docs/enterprise/configuration/flexible-config/)

## When to activate
- User asks to audit security: "check security", "security audit", "is this secure"
- User mentions security concerns: "secure my api", "security issues", "vulnerabilities"
- User wants to review authentication/authorization: "check auth", "review authentication"
- User wants to find security problems: "security scan", "find security issues"
- After completing configuration changes to verify security posture

## What this skill does

1. **Performs security audit** using smart three-tier validation:
   - Native `krakend audit` command if available (most comprehensive)
   - Docker-based audit if native unavailable
   - Basic security checks as fallback (CORS, auth, rate limiting, debug endpoints)

2. **Categorizes security issues** by severity:
   - **Critical**: Immediate action required (exposed credentials, no authentication)
   - **High**: Serious security gaps (missing authentication, debug enabled)
   - **Medium**: Important improvements (missing CORS, no rate limiting)
   - **Low**: Best practice recommendations (security headers, logging)
   - **Info**: Informational notices (configuration observations)

3. **Provides specific remediation** for each finding:
   - Exact location of the issue (JSON path)
   - Step-by-step fix instructions
   - Example configuration snippets
   - Links to relevant documentation

4. **Checks common vulnerabilities**:
   - Missing or weak authentication
   - Authorization bypasses
   - Exposed sensitive endpoints
   - Missing rate limiting (DoS protection)
   - Lack of CORS configuration
   - Debug endpoints in production
   - Insecure headers
   - Overly permissive configurations

## Tools used
- `audit_security` - Comprehensive security audit (smart fallback: native KrakenD → Docker → basic checks)
- `list_features` - Browse available security features and their edition requirements
- `get_feature_config_template` - Get configuration templates for security features
- `search_documentation` - Find relevant security documentation
- `validate_config` - Validate configuration structure alongside security checks

## Output format

Provide a clear, actionable security report:

```
# KrakenD Security Audit Report

## Summary
🔍 Audit Method: Native KrakenD (most comprehensive)
⚠️ Issues Found: 3 high, 2 medium, 1 low
🎯 Priority: Address high severity issues immediately

## Critical Issues
None found ✓

## High Severity Issues

### 1. Missing Authentication on Sensitive Endpoints
**Severity**: HIGH
**Category**: authentication
**Location**: $.endpoints[2] (POST /api/users)

**Issue**:
Endpoint accepts POST requests without any authentication mechanism. This allows anonymous users to create resources.

**Remediation**:
1. Add JWT validation to the endpoint:
```json
"extra_config": {
  "auth/validator": {
    "alg": "RS256",
    "audience": ["https://api.example.com"],
    "jwk_url": "https://auth.example.com/.well-known/jwks.json"
  }
}
```

**References**:
- https://www.krakend.io/docs/authorization/jwt-validation/
- https://www.krakend.io/docs/enterprise/authentication/api-keys/

---

### 2. Debug Endpoint Enabled
**Severity**: HIGH
**Category**: exposure
**Location**: $.extra_config["debug_endpoint"]

**Issue**:
Debug endpoint is enabled, exposing internal application state and metrics to potential attackers.

**Remediation**:
Remove or disable the debug endpoint in production:
```json
"extra_config": {
  "debug_endpoint": false
}
```
Or remove the entire "debug_endpoint" configuration block.

**References**:
- https://www.krakend.io/docs/service-settings/debug-endpoint/

## Medium Severity Issues

### 3. Missing CORS Configuration
**Severity**: MEDIUM
**Category**: security-headers
**Location**: $.extra_config (root level)

**Issue**:
No CORS configuration found. This may cause browser requests to fail or allow all origins by default.

**Remediation**:
Add CORS configuration with explicit allowed origins:
```json
"extra_config": {
  "security/cors": {
    "allow_origins": ["https://yourdomain.com"],
    "allow_methods": ["GET", "POST", "PUT"],
    "allow_headers": ["Authorization", "Content-Type"],
    "expose_headers": ["Content-Length"],
    "max_age": "12h",
    "allow_credentials": true
  }
}
```

**References**:
- https://www.krakend.io/docs/service-settings/cors/

---

### 4. No Rate Limiting Configured
**Severity**: MEDIUM
**Category**: dos-protection
**Location**: $.endpoints[*] (all endpoints)

**Issue**:
None of the endpoints have rate limiting configured, leaving the API vulnerable to abuse and DoS attacks.

**Remediation**:
Add rate limiting to sensitive endpoints:
```json
"extra_config": {
  "qos/ratelimit/router": {
    "max_rate": 100,
    "capacity": 100,
    "client_max_rate": 10,
    "client_capacity": 10
  }
}
```

**References**:
- https://www.krakend.io/docs/endpoints/rate-limit/

## Low Severity Issues

### 5. Missing Security Headers
**Severity**: LOW
**Category**: security-headers
**Location**: $.extra_config (root level)

**Issue**:
Security headers like X-Frame-Options, X-Content-Type-Options not configured.

**Remediation**:
Consider adding security headers plugin if available in your KrakenD edition.

## Best Practices Recommendations

✓ Circuit breakers configured for backends
✓ Timeouts configured
⚠️ Consider adding request/response logging for security monitoring
⚠️ Consider implementing API key authentication for service-to-service calls
⚠️ Review and minimize backend exposure (principle of least privilege)

## Validation Method
Validated using: **Native KrakenD audit** (most comprehensive)

## Next Steps

1. **Immediate**: Fix all high severity issues (authentication, debug endpoint)
2. **Short-term**: Address medium severity issues (CORS, rate limiting)
3. **Long-term**: Implement low severity improvements and best practices
4. **Ongoing**: Run security audits regularly, especially after configuration changes
```

## Best practices

1. **Always show severity** - Use clear severity levels (CRITICAL, HIGH, MEDIUM, LOW, INFO)
2. **Prioritize findings** - Show critical/high severity issues first
3. **Be specific and actionable** - Don't just say "insecure", explain what's wrong and how to fix
4. **Include context** - Show exact location using JSON paths
5. **Provide examples** - Include working configuration snippets for remediation
6. **Link to docs** - Always include relevant KrakenD documentation URLs
7. **Consider edition** - Recommend CE-compatible solutions unless user has EE
8. **Show audit method** - Always indicate which validation method was used (native/Docker/basic)
9. **Balance security with usability** - Don't recommend overly restrictive configs without explanation
10. **Follow up** - Suggest re-running audit after fixes are applied

## Examples

### Example 1: User asks "Is my API secure?"

**Response:**
"I'll perform a comprehensive security audit of your KrakenD configuration."

[Use `audit_security` with the configuration]

[Present structured report as shown above]

"I found 3 high severity issues that should be addressed immediately. Would you like me to help you fix these issues?"

### Example 2: User asks "check security before production"

**Response:**
"I'll audit your configuration for security issues before production deployment."

[Use `audit_security` with production config]

[Present findings]

"Your configuration has 2 critical issues that must be fixed before production:
1. No authentication on admin endpoints
2. Debug mode still enabled

Would you like me to fix these now?"

### Example 3: User implements authentication and asks for re-audit

**Response:**
"I'll re-run the security audit to verify your authentication changes."

[Use `audit_security` again]

[Compare with previous results if available]

"Great progress! The authentication issue is now resolved. Remaining items:
- 1 high severity: Debug endpoint still enabled
- 2 medium severity: Missing CORS and rate limiting

Shall we address these next?"

### Example 4: Basic checks fallback scenario

**Response:**
"KrakenD binary and Docker are not available, so I'll perform basic security checks."

[Use `audit_security` which falls back to basic checks]

"I performed basic security checks and found:
- Missing CORS configuration
- No authentication on POST endpoints
- No rate limiting configured
- Debug endpoint enabled

Note: For a comprehensive audit, install KrakenD or Docker to run the full `krakend audit` command. These basic checks cover common issues but may miss advanced security problems."

## Error handling

- **If config file not found**: Ask user which file to audit
- **If config is invalid JSON**: Run syntax check first, then report
- **If audit produces no output**: Explain that no issues were found (best case!)
- **If KrakenD audit fails**: Fall back to Docker, then basic checks automatically
- **If too many issues found (>15)**: Group by severity and offer to show details incrementally
- **If user has mix of CE/EE features**: Note in recommendations which features require EE

## Integration with other skills

- **After config-builder creates new config** → Automatically suggest security audit
- **If config-validator finds issues** → Mention that security audit can find security-specific problems
- **Before production deployment** → Strongly recommend running security audit
- **After migration-assistant** → Suggest security audit to ensure no security regressions
- **If user asks about specific features** (auth, CORS, etc.) → Offer to run full security audit

## Security categories explained

- **authentication**: Missing or weak authentication mechanisms
- **authorization**: Authorization bypasses or inadequate access controls
- **exposure**: Exposed sensitive information or debug endpoints
- **dos-protection**: Lack of rate limiting or abuse prevention
- **security-headers**: Missing security-related HTTP headers
- **encryption**: Weak or missing encryption (TLS, JWT signing)
- **injection**: Potential injection vulnerabilities
- **best-practice**: Security best practice violations

## When to run security audits

- ✅ Before initial deployment
- ✅ After any configuration changes
- ✅ After adding new endpoints
- ✅ Before major releases
- ✅ After security incidents
- ✅ Periodically (monthly/quarterly)
- ✅ After upgrading KrakenD versions
- ✅ When changing authentication mechanisms
