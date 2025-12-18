# KrakenD AI Assistant for Claude Code

**Intelligent Claude Code plugin for KrakenD API Gateway with proactive Skills and Architecture Agent.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Plugin Version](https://img.shields.io/badge/Plugin-0.6.3-blue.svg)](https://github.com/krakend/claude-code-plugin)
[![MCP Server](https://img.shields.io/badge/MCP%20Server-0.6.2-green.svg)](https://github.com/krakend/mcp-server)

## Overview

KrakenD AI Assistant is a powerful Claude Code plugin that brings intelligent KrakenD configuration assistance directly into your development workflow. It combines the universal [KrakenD MCP Server](https://github.com/krakend/mcp-server) with Claude Code-specific Skills and an Architecture Agent for an enhanced experience.

### What Makes This Special?

- 🎯 **Proactive Skills** - Auto-activate based on your actions and questions
- 🏗️ **Architecture Agent** - Design multi-service API architectures
- 🤖 **Automatic Binary Management** - Downloads and manages MCP server automatically
- ✅ **Zero Configuration** - Works out of the box with SessionStart hook
- 🔄 **Version Management** - Automatic version checking and updates

## Features

### 4 Proactive Skills

#### 1. **Config Validator**
Auto-activates when you mention validation or have config issues.

```
You: "validate my krakend config"
Skill: Runs version-aware validation with specific error messages
```

#### 2. **Config Builder**
Auto-activates when you want to create or modify configurations.

```
You: "create a new endpoint for user authentication"
Skill: Interactive config generation with best practices
```

#### 3. **Feature Explorer**
Auto-activates when you ask about KrakenD features.

```
You: "what rate limiting options does krakend have?"
Skill: Shows features with CE/EE compatibility and examples
```

#### 4. **Security Auditor**
Auto-activates when you mention security or audits.

```
You: "audit my config security"
Skill: Comprehensive security analysis with actionable fixes
```

### 1 Specialized Agent

#### **Config Architect Agent**
Spawns automatically for complex multi-service architectures.

```
You: "design an API gateway for microservices with auth, rate limiting, and caching"
Agent: Creates complete architecture with multiple endpoints, backends, and best practices
```

## Installation

### Via Claude Code

Install from the KrakenD marketplace or local development copy:

```bash
# From KrakenD marketplace (recommended)
/plugin marketplace add krakend/claude-code-plugin
/plugin install krakend-ai-assistant

# From local (development)
/plugin add ~/Code/krakend/claude-code-plugin
```

The plugin will automatically:
1. Download the KrakenD MCP Server v0.6.2 (fully offline-capable with embedded docs)
2. Verify checksums for security
3. Install to the plugin directory
4. Start the MCP server connection

**Note**: The MCP server binary includes embedded KrakenD documentation and search index (~21MB), making it fully functional offline. You can optionally update documentation using the `refresh_documentation_index` tool.

### Manual Installation

If you want to install the MCP server manually:

```bash
# The plugin will handle this automatically, but you can also:
cd ~/Code/krakend/claude-code-plugin
./scripts/install-mcp.sh
```

## Usage

### Skills Auto-Activate

Just work naturally - skills activate automatically:

```
You: "I need to validate my krakend.json"
→ config-validator skill activates

You: "How do I add JWT validation?"
→ feature-explorer skill activates

You: "Check security of my config"
→ security-auditor skill activates

You: "Create an endpoint for /api/users"
→ config-builder skill activates
```

### Agent for Complex Tasks

For architectural decisions:

```
You: "I need to design an API gateway for a microservices architecture with:
- User service (authentication)
- Product service (with caching)
- Order service (with rate limiting)
- All services need CORS and security headers"

→ config-architect agent spawns and designs complete architecture
```

## How It Works

This plugin provides an enhanced KrakenD experience through:

1. **4 Proactive Skills** - Auto-activate when you need them
2. **1 Architecture Agent** - Designs complex multi-service setups
3. **[KrakenD MCP Server](https://github.com/krakend/mcp-server)** - Automatically managed, provides validation, generation, and documentation tools

The plugin handles everything automatically - just install and start using it!

## For Developers

Want to contribute or customize the plugin? See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Local development setup
- How to create/modify Skills
- How to create/modify Agents
- Testing guidelines

## Troubleshooting

### MCP Server Won't Start

```bash
# Check if binary exists
ls -la ~/.claude/plugins/krakend-ai-assistant/servers/krakend-mcp-server/

# Manually reinstall
cd ~/.claude/plugins/krakend-ai-assistant
./scripts/install-mcp.sh --verbose

# Check logs
cat ~/.claude/plugins/krakend-ai-assistant/.install.log
```

### Version Mismatch

The plugin automatically downloads the correct MCP server version. If you see errors, check that the required release exists at: https://github.com/krakend/mcp-server/releases

### Skills Not Activating

1. Check that the plugin is installed: `/plugin list`
2. Verify MCP server is running: Check Claude Code's MCP status
3. Try explicit activation: `/plugin activate krakend-ai-assistant`

## Related Projects

- **[KrakenD MCP Server](https://github.com/krakend/mcp-server)** - Universal MCP server (used by this plugin)
- **[KrakenD](https://github.com/krakend/krakend-ce)** - Ultra-performant open-source API Gateway

## Support

- **Issues**: [GitHub Issues](https://github.com/krakend/claude-code-plugin/issues)
- **MCP Server Issues**: [MCP Server Issues](https://github.com/krakend/mcp-server/issues)
- **Documentation**: [krakend.io/docs](https://www.krakend.io/docs/)
- **Community**: [KrakenD Community](https://github.com/krakend/krakend-ce/discussions)

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 License - see [LICENSE](LICENSE) file for details.

## Security

For security concerns, see [SECURITY.md](SECURITY.md).

---

**Version**: 0.6.3
**Features**: 4 Proactive Skills + 1 Architecture Agent + Automatic MCP Management

---

**Made with ❤️ by [KrakenD](https://www.krakend.io)**

*Enhanced AI assistance for the world's fastest API Gateway*
