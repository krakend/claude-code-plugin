# Contributing to KrakenD AI Assistant for Claude Code

Thank you for your interest in contributing to the KrakenD AI Assistant plugin!

## Overview

This is a Claude Code plugin that provides intelligent KrakenD configuration assistance through:
- 4 proactive Skills
- 1 specialized Architecture Agent
- Integration with [KrakenD MCP Server](https://github.com/krakend/mcp-server)

## Development Setup

### Prerequisites

- Claude Code installed
- Git
- Go 1.21+ (optional, for MCP server development)

### Local Setup

1. Clone the repository:
```bash
git clone https://github.com/krakend/claude-code-plugin.git
cd claude-code-plugin
```

2. Install the plugin locally in Claude Code:
```bash
# In Claude Code
/plugin add ~/path/to/claude-code-plugin
```

3. Test the plugin:
```bash
# Skills auto-activate based on queries
# Or manually: /plugin activate krakend-ai-assistant
```

## Project Structure

```
claude-code-plugin/
├── .claude-plugin/
│   ├── plugin.json          # Plugin metadata and hooks
│   └── marketplace.json     # Marketplace listing
├── .mcp.json                # MCP server configuration
├── skills/                  # 4 proactive skills
│   ├── config-builder/
│   ├── config-validator/
│   ├── feature-explorer/
│   └── security-auditor/
├── agents/                  # Specialized agents
│   └── config-architect.md
├── scripts/
│   └── install-mcp.sh       # MCP server installation
└── README.md
```

## Contributing to Skills

### What is a Skill?

A Skill is a proactive Claude Code feature that auto-activates based on user queries and actions.

### Skill Structure

Each skill is defined in `skills/{skill-name}/SKILL.md`:

```markdown
---
name: skill-name
description: Brief description
---

# Skill Name

## Purpose
What this skill does

## When to activate
- Trigger condition 1
- Trigger condition 2

## What this skill does
Detailed behavior

## Tools used
- MCP tool 1
- MCP tool 2

## Output format
Expected output structure

## Best practices
Guidelines for behavior

## Examples
Usage examples
```

### Adding a New Skill

1. Create directory: `skills/new-skill-name/`
2. Create `SKILL.md` with proper frontmatter
3. Define activation triggers clearly
4. List MCP tools the skill will use
5. Provide examples of expected behavior
6. Test the skill with various queries

### Testing Skills

Skills are tested by:
1. Triggering activation conditions
2. Verifying correct MCP tools are called
3. Checking output format matches specification
4. Testing edge cases and error handling

## Contributing to Agents

### What is an Agent?

An Agent is a specialized subprocess that handles complex, multi-step tasks autonomously.

### Agent Structure

Agents are defined in `agents/{agent-name}.md`:

```markdown
---
name: agent-name
description: Brief description
tools: [list, of, allowed, tools]
---

# Agent Name

## Purpose
What this agent specializes in

## When to spawn
Conditions for spawning this agent

## Capabilities
What the agent can do

## Tools available
- Tool 1: Description
- Tool 2: Description

## Expected behavior
How the agent should operate

## Examples
Usage scenarios
```

### Adding a New Agent

1. Create `agents/new-agent-name.md`
2. Define agent's specialization
3. List available MCP tools
4. Specify spawn conditions
5. Document expected behavior
6. Provide usage examples

## Modifying MCP Server Integration

### MCP Server Dependency

This plugin depends on the [KrakenD MCP Server](https://github.com/krakend/mcp-server).

Current version: **0.6.3**

### Updating MCP Server Version

To update the required MCP server version:

1. Edit `scripts/install-mcp.sh`:
```bash
# Version of MCP server required by this plugin
REQUIRED_MCP_VERSION="0.7.0"  # Update this
```

2. Update plugin version in `.claude-plugin/plugin.json`

3. Test installation:
```bash
./scripts/install-mcp.sh --verbose
```

4. Update README.md version compatibility matrix

### Testing MCP Integration

```bash
# Check MCP server is running
# In Claude Code, check MCP status

# Test MCP tools are accessible
# Skills should be able to call MCP tools

# Verify version checking works
# Script should detect version mismatches
```

## Code Style

### Markdown Files

- Use clear, concise language
- Follow existing formatting patterns
- Include examples for clarity
- Keep frontmatter consistent

### Bash Scripts

- Follow existing script style
- Add comments for complex logic
- Use meaningful variable names
- Handle errors gracefully
- Provide verbose mode for debugging

## Testing

### Manual Testing Checklist

- [ ] Plugin installs successfully
- [ ] MCP server binary downloads/builds
- [ ] Version checking works correctly
- [ ] Skills activate on correct triggers
- [ ] Agent spawns for complex tasks
- [ ] MCP tools are accessible
- [ ] Error messages are clear and helpful

### Testing on Different Platforms

If modifying `install-mcp.sh`:
- [ ] Test on macOS (Intel)
- [ ] Test on macOS (Apple Silicon)
- [ ] Test on Linux (x64)
- [ ] Test on Linux (ARM64)
- [ ] Test on Windows (WSL)

## Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Make** your changes
4. **Test** thoroughly (see checklist above)
5. **Commit** with clear messages
6. **Push** to your branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### PR Guidelines

- **Clear Description**: Explain what and why
- **Reference Issues**: Link related issues
- **Test Evidence**: Show it works
- **Update Docs**: Keep README/skills updated
- **One Feature**: Keep PRs focused

### Commit Message Format

```
type(scope): brief description

Detailed explanation if needed.

- Change 1
- Change 2
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(skills): add new config-optimizer skill
fix(install): handle download timeout gracefully
docs(readme): update installation instructions
```

## Reporting Issues

### Bug Reports

Include:
- Plugin version
- MCP server version
- Claude Code version
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages or logs

### Feature Requests

Include:
- Clear description of feature
- Use case / motivation
- Proposed implementation (if any)
- Examples of expected behavior

### Logs and Debugging

Installation logs: `~/.claude/plugins/krakend-ai-assistant/.install.log`

Verbose installation:
```bash
./scripts/install-mcp.sh --verbose
```

## Documentation

- **Skills**: Document in `SKILL.md` files
- **Agents**: Document in agent `.md` files
- **Scripts**: Add inline comments
- **README**: Update for user-facing changes
- **This file**: Update for process changes

## Release Process

1. Update version in:
   - `.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`
   - `README.md`
   - `scripts/install-mcp.sh` (REQUIRED_MCP_VERSION if needed)

2. Create release notes

3. Tag release: `git tag v0.7.0`

4. Push: `git push && git push --tags`

Note: Plugin releases are lightweight (no binary compilation needed)

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Security**: See [SECURITY.md](SECURITY.md)
- **Community**: [KrakenD Community](https://github.com/krakend/krakend-ce/discussions)

## Related Contributions

Consider contributing to:
- **[KrakenD MCP Server](https://github.com/krakend/mcp-server)** - The underlying MCP server
- **[KrakenD](https://github.com/krakend/krakend-ce)** - The API Gateway itself

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to make KrakenD better.

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.

---

Thank you for helping make KrakenD AI Assistant better! 🚀
