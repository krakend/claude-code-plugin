#!/bin/bash
##
## install-mcp.sh - Download and install KrakenD MCP Server binary
##
## This script is executed automatically when the plugin is installed via Claude Code.
## It detects the platform, downloads the appropriate binary from GitHub Releases,
## verifies its checksum, and installs it.
##
## Usage:
##   ./install-mcp.sh              # Normal mode
##   ./install-mcp.sh -v           # Verbose mode
##   ./install-mcp.sh --verbose    # Verbose mode
##

set -e  # Exit on error

# Version of MCP server required by this plugin
REQUIRED_MCP_VERSION="0.6.3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verbose mode flag
VERBOSE=0
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=1
fi

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Setup log file
LOG_FILE="${CLAUDE_PLUGIN_ROOT:-.}/.install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

log "Installing KrakenD MCP Server binary..."
log_verbose "Log file: $LOG_FILE"

# Detect platform
detect_platform() {
    local os arch

    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    log_verbose "Raw platform: OS=$os, ARCH=$arch"

    # Normalize OS name
    case "$os" in
        darwin)
            OS_NAME="darwin"
            ;;
        linux)
            OS_NAME="linux"
            ;;
        mingw*|msys*|cygwin*|windows*)
            OS_NAME="windows"
            ;;
        *)
            log_error "Unsupported operating system: $os"
            log_error "Supported: macOS (darwin), Linux, Windows"
            exit 1
            ;;
    esac

    # Normalize architecture name
    case "$arch" in
        x86_64|amd64)
            ARCH_NAME="amd64"
            ;;
        arm64|aarch64)
            ARCH_NAME="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            log_error "Supported: x86_64/amd64, arm64/aarch64"
            exit 1
            ;;
    esac

    # Binary filename
    BINARY_NAME="krakend-mcp-${OS_NAME}-${ARCH_NAME}"
    if [ "$OS_NAME" = "windows" ]; then
        BINARY_NAME="${BINARY_NAME}.exe"
    fi

    log "Platform detected: ${OS_NAME}-${ARCH_NAME}"
    log_verbose "Binary name: $BINARY_NAME"
}

# Read version from plugin.json
get_version() {
    local plugin_json="${CLAUDE_PLUGIN_ROOT:-.}/.claude-plugin/plugin.json"

    if [ ! -f "$plugin_json" ]; then
        log_error "plugin.json not found at: $plugin_json"
        exit 1
    fi

    # Extract version using grep/sed (portable, no jq dependency)
    VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$plugin_json" | sed 's/.*"\([^"]*\)".*/\1/')

    if [ -z "$VERSION" ]; then
        log_error "Could not extract version from plugin.json"
        exit 1
    fi

    log "Plugin version: $VERSION"
    log_verbose "Plugin config: $plugin_json"
}

# Try to download binary from GitHub Releases
# Returns: 0 on success, 1 on failure
try_download_binary() {
    local base_url="https://github.com/krakend/mcp-server/releases/download"
    local download_url="${base_url}/v${REQUIRED_MCP_VERSION}/${BINARY_NAME}"
    local checksums_url="${base_url}/v${REQUIRED_MCP_VERSION}/checksums.txt"

    DOWNLOAD_DIR="${CLAUDE_PLUGIN_ROOT:-.}/servers/krakend-mcp-server"
    BINARY_PATH="${DOWNLOAD_DIR}/krakend-mcp-server"

    log_verbose "Download URL: $download_url"
    log_verbose "Checksums URL: $checksums_url"
    log_verbose "Destination: $BINARY_PATH"

    # Create directory if it doesn't exist
    mkdir -p "$DOWNLOAD_DIR"

    # Try to download binary
    log "Attempting to download pre-compiled binary..."
    if [ $VERBOSE -eq 1 ]; then
        if ! curl -L --fail --progress-bar -o "$BINARY_PATH" "$download_url" 2>&1; then
            log_warning "Download failed (release may not exist yet)"
            return 1
        fi
    else
        if ! curl -L --fail --silent --show-error -o "$BINARY_PATH" "$download_url" 2>&1; then
            log_warning "Download failed (release may not exist yet)"
            return 1
        fi
    fi

    log_success "Binary downloaded"

    # Try to download checksums
    log "Downloading checksums..."
    CHECKSUMS_FILE="${DOWNLOAD_DIR}/checksums.txt"
    if ! curl -L --fail --silent --show-error -o "$CHECKSUMS_FILE" "$checksums_url" 2>&1; then
        log_warning "Could not download checksums file"
        log_warning "Skipping checksum verification (not recommended)"
        return 0  # Continue without checksum verification
    fi

    log_verbose "Checksums file: $CHECKSUMS_FILE"

    # Verify checksum
    if ! verify_checksum; then
        return 1
    fi

    return 0
}

# Verify binary checksum
# Returns: 0 on success, 1 on failure
verify_checksum() {
    log "Verifying checksum..."

    if [ ! -f "$CHECKSUMS_FILE" ]; then
        log_warning "Checksums file not found, skipping verification"
        return 0
    fi

    # Extract expected checksum for our binary
    local expected_checksum=$(grep "$BINARY_NAME" "$CHECKSUMS_FILE" | awk '{print $1}')

    if [ -z "$expected_checksum" ]; then
        log_warning "Checksum not found for $BINARY_NAME in checksums file"
        return 0
    fi

    log_verbose "Expected checksum: $expected_checksum"

    # Calculate actual checksum
    local actual_checksum
    if command -v shasum >/dev/null 2>&1; then
        actual_checksum=$(shasum -a 256 "$BINARY_PATH" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual_checksum=$(sha256sum "$BINARY_PATH" | awk '{print $1}')
    else
        log_warning "sha256sum/shasum not found, skipping checksum verification"
        return 0
    fi

    log_verbose "Actual checksum:   $actual_checksum"

    # Compare checksums
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        log_error "Checksum verification failed!"
        log_error "Expected: $expected_checksum"
        log_error "Got:      $actual_checksum"
        log_error "Binary may be corrupted or tampered with"
        rm -f "$BINARY_PATH"
        return 1
    fi

    log_success "Checksum verified"
    return 0
}

# Install binary
install_binary() {
    log "Installing binary..."

    # Make executable
    chmod +x "$BINARY_PATH"
    log_verbose "Set executable permissions"

    # Verify it works
    log "Verifying binary..."
    if ! "$BINARY_PATH" --version >/dev/null 2>&1; then
        log_error "Binary verification failed"
        log_error "The downloaded binary does not execute properly"
        rm -f "$BINARY_PATH"
        exit 1
    fi

    # Get version output
    local binary_version=$("$BINARY_PATH" --version 2>&1)
    log_success "Binary installed successfully"
    log_verbose "Binary output: $binary_version"

    # Cleanup
    rm -f "$CHECKSUMS_FILE"
    log_verbose "Cleaned up temporary files"
}

# Check if correct version of MCP server is already installed
check_installed_version() {
    local binary_path

    if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
        binary_path="$CLAUDE_PLUGIN_ROOT/servers/krakend-mcp-server/krakend-mcp-server"
    else
        local project_root="$(cd "$(dirname "$0")/.." && pwd)"
        binary_path="$project_root/servers/krakend-mcp-server/krakend-mcp-server"
    fi

    if [ ! -f "$binary_path" ]; then
        log_verbose "Binary not found at: $binary_path"
        return 1
    fi

    # Check if binary is executable and works
    if ! "$binary_path" --version >/dev/null 2>&1; then
        log_verbose "Binary exists but doesn't work, will reinstall"
        return 1
    fi

    # Get installed version
    local installed_version=$("$binary_path" --version 2>&1 | grep -o 'version [0-9.]*' | cut -d' ' -f2)

    # Check if it matches required version
    if [ "$installed_version" = "$REQUIRED_MCP_VERSION" ]; then
        log_success "MCP server v$installed_version already installed (required: v$REQUIRED_MCP_VERSION)"
        BINARY_PATH="$binary_path"
        return 0
    else
        log "MCP server v$installed_version found, but v$REQUIRED_MCP_VERSION required"
        log "Will download/build correct version..."
        return 1
    fi
}

# Main execution
main() {
    log_verbose "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT:-(not set)}"
    log_verbose "Script directory: $(dirname "$0")"

    detect_platform
    get_version

    # Check if correct version already exists
    if check_installed_version; then
        log "Location: $BINARY_PATH"
        log_verbose "Skipping installation (correct version already installed)"
        exit 0
    fi

    log "Binary not found or not working, proceeding with installation..."

    # Try to download pre-compiled binary
    if try_download_binary; then
        log_success "Downloaded pre-compiled binary from GitHub Releases"

        # Install and verify the binary
        install_binary
    else
        # Download failed
        echo ""
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Installation Failed"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_error "Could not download KrakenD MCP Server v${REQUIRED_MCP_VERSION}"
        echo ""
        log "This usually means:"
        log "  • GitHub Releases may be temporarily unavailable"
        log "  • The required version hasn't been released yet"
        log "  • Network connectivity issues"
        echo ""
        log "Solutions:"
        echo ""
        echo "  1. Check if the release exists:"
        echo "     https://github.com/krakend/mcp-server/releases/tag/v${REQUIRED_MCP_VERSION}"
        echo ""
        echo "  2. Download and install manually:"
        echo "     curl -L -o krakend-mcp-server \\"
        echo "       https://github.com/krakend/mcp-server/releases/download/v${REQUIRED_MCP_VERSION}/krakend-mcp-${OS_NAME}-${ARCH_NAME}"
        echo "     chmod +x krakend-mcp-server"
        echo "     mkdir -p ${DOWNLOAD_DIR}"
        echo "     mv krakend-mcp-server ${DOWNLOAD_DIR}/"
        echo ""
        echo "  3. Try again later (GitHub may be temporarily unavailable)"
        echo ""
        if [ $VERBOSE -eq 1 ]; then
            echo "  Check the log for details: $LOG_FILE"
            echo ""
        else
            echo "  Run with --verbose for detailed logs:"
            echo "     $0 --verbose"
            echo ""
        fi
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi

    echo ""
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Installation Complete!"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log "Binary location: $BINARY_PATH"
    log "Platform: ${OS_NAME}-${ARCH_NAME}"
    log "Version: $VERSION"

    if [ $VERBOSE -eq 1 ]; then
        echo ""
        log_verbose "Installation log saved to: $LOG_FILE"
    fi
}

# Run main function
main
