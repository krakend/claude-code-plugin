# Security Policy

## Overview

KrakenD AI Assistant is a Claude Code plugin that provides Skills and an Architecture Agent for KrakenD configuration assistance. The plugin automatically manages the [KrakenD MCP Server](https://github.com/krakend/mcp-server), which runs locally on your machine.

## Supported Versions

| Version | Supported          | Notes                           |
| ------- | ------------------ | ------------------------------- |
| 0.6.x   | :white_check_mark: | Current stable release          |
| < 0.6.0 | :x:                | Please upgrade to latest version|

We recommend always using the latest version from the `main` branch for the most up-to-date security fixes.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

KrakenD takes cybersecurity seriously and follows a responsible disclosure process. We appreciate the security research community's help in keeping our software secure.

### How to Report

**Email**: [email protected]
- Include "KrakenD AI Assistant Security" in the subject line
- Provide detailed information about the vulnerability
- KrakenD will acknowledge receipt and provide next steps

### What to Include

When reporting a vulnerability, please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)
- Your contact information
- Whether you want to be credited for the discovery

### Responsible Disclosure

We ask security researchers to:
- ✅ **Do** allow KrakenD time to investigate and fix the issue
- ✅ **Do** provide detailed reproduction steps
- ✅ **Do** work with us to understand the impact
- ❌ **Don't** publish vulnerabilities before fixes are released
- ❌ **Don't** divulge exploit details or proof-of-concept code publicly
- ❌ **Don't** test against production systems

### Response Process

1. **Acknowledgment**: KrakenD acknowledges receipt and begins investigation
2. **Verification**: Team reproduces and confirms the vulnerability
3. **CVE Assignment**: Undisclosed CVE ID created if confirmed
4. **Fix Development**: Patch developed and tested
5. **Release**: Fix applied to latest version
6. **Public Disclosure**: Security advisory published via GitHub and newsletters

### Recognition

KrakenD offers non-monetary recognition:
- Credit in CVE ID (if desired)
- Public acknowledgment in release notes
- Addition to KrakenD Contributors GitHub organization
- Opportunity to engage with technical staff
- KrakenD merchandise

### Response Timeline

We aim to respond within:
- **Critical vulnerabilities**: 48 hours
- **High severity**: 1 week
- **Medium/Low severity**: 2 weeks

Patches will be released as soon as verified and tested.

## Security Considerations

### Plugin Security

**What the plugin does:**
- ✅ Downloads KrakenD MCP Server binary from GitHub Releases
- ✅ Verifies SHA256 checksums before installation
- ✅ Installs to plugin directory (no sudo required)
- ✅ Runs MCP server locally via stdio transport

**Installation safety:**
- Binary downloaded from official GitHub Releases only
- Checksum verification ensures integrity
- No elevated privileges needed
- No modifications outside plugin directory

### MCP Server Security

The underlying MCP server security details are documented in the [MCP Server SECURITY.md](https://github.com/krakend/mcp-server/blob/main/SECURITY.md).

Key points:
- Runs locally with your user permissions
- No network ports exposed
- No remote access
- Processes KrakenD configurations locally

## Best Practices for Users

### 1. Keep Updated
```bash
# Check current plugin version
# In Claude Code: /plugin list

# Update plugin
# In Claude Code: /plugin update krakend-ai-assistant

# MCP server binary is automatically managed by the plugin
# It will download the required version on SessionStart
```

### 2. Verify Binary Downloads
```bash
# Plugin verifies checksums automatically
# Check installation log if concerned:
cat ~/.claude/plugins/krakend-ai-assistant/.install.log
```

### 3. Review Configurations Before Deployment
The AI assistant helps create configurations, but **always review**:
- Authentication settings
- CORS policies
- Rate limiting
- Debug endpoints (disable in production)
- Security headers

### 4. Use in Trusted Environments
- Only run in directories you trust
- Avoid running in directories with sensitive data
- Review any custom skills or agents before installing

### 5. Review Plugin Permissions
```bash
# Plugin only writes to its own directory
ls -la ~/.claude/plugins/krakend-ai-assistant/

# MCP server binary location
ls -la ~/.claude/plugins/krakend-ai-assistant/servers/
```

## Security Features

### Plugin Security Features
- **Checksum Verification**: SHA256 verification of downloaded binaries
- **Official Sources**: Only downloads from github.com/krakend/mcp-server
- **No Elevated Privileges**: Runs entirely within user permissions
- **Isolated Installation**: Plugin directory only, no system modifications

### MCP Server Security Features
See [MCP Server SECURITY.md](https://github.com/krakend/mcp-server/blob/main/SECURITY.md) for details on:
- Input validation
- Safe file operations
- Error handling
- Configuration validation security

## Known Limitations

### Plugin Scope
This plugin provides AI assistance but:
- Does not replace security audits
- Generated configs should be reviewed before deployment
- Use the `audit_security` skill for security checks

### Local Trust Model
- Plugin assumes trusted local environment
- No authentication between Claude Code and MCP server
- Designed for single-user local development
- Not for remote or multi-tenant deployments

### Dependencies
- Plugin depends on KrakenD MCP Server (separate project)
- MCP Server security: see [MCP Server SECURITY.md](https://github.com/krakend/mcp-server/blob/main/SECURITY.md)
- Claude Code platform security: managed by Anthropic

## Responsible Disclosure

We follow responsible disclosure practices:
1. Report received and acknowledged
2. Issue verified and severity assessed
3. Fix developed and tested
4. Security advisory published
5. Credit given to reporter (if desired)

## Security Resources

- **MCP Server Security**: https://github.com/krakend/mcp-server/blob/main/SECURITY.md
- **KrakenD Security Documentation**: https://www.krakend.io/docs/authorization/
- **MCP Protocol Security**: https://modelcontextprotocol.io/docs/security

## Questions?

For security-related questions that are not vulnerabilities:
- Open a [GitHub Discussion](https://github.com/krakend/claude-code-plugin/discussions)
- Join [KrakenD Community](https://github.com/krakend/krakend-ce/discussions)

---

**Last Updated**: December 15, 2025
**Policy Version**: 1.0
