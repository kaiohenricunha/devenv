#!/usr/bin/env bash

set -euo pipefail

DEVENV_SCRIPT_NAME="ai_tools"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script supports only Linux. Detected: $(uname -s). Aborting."
  exit 1
fi

load_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    . "$nvm_dir/nvm.sh"
    nvm use default >/dev/null 2>&1 || true
  fi
}

ensure_npm() {
  if command -v npm >/dev/null 2>&1; then
    return 0
  fi

  load_nvm
  if command -v npm >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

ensure_npm_global_bin_on_path() {
  local npm_global_prefix=""
  local npm_global_bin=""
  npm_global_prefix="$(npm prefix -g 2>/dev/null || true)"
  if [[ -z "$npm_global_prefix" ]]; then
    return 0
  fi

  npm_global_bin="$npm_global_prefix/bin"
  if [[ -n "$npm_global_bin" && -d "$npm_global_bin" && ":$PATH:" != *":$npm_global_bin:"* ]]; then
    export PATH="$npm_global_bin:$PATH"
    append_once_to_file "$HOME/.zshrc" "export PATH=\"$npm_global_bin:\$PATH\""
    append_once_to_file "$HOME/.bashrc" "export PATH=\"$npm_global_bin:\$PATH\""
  fi
}

print_tool_version() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    "$tool" --version
  else
    echo "$tool: not installed"
  fi
}

print_path_guidance() {
  local tool="$1"
  echo "$tool installed but '$tool' is not on PATH in this shell. Try: export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed:"
    print_tool_version claude
    return 0
  fi

  echo "Installing Claude Code (native installer)..."
  curl --retry 3 --max-time 60 -fsSL https://claude.ai/install.sh | sh
  # Refresh PATH in case the installer placed the binary in ~/.claude/local/bin or similar
  export PATH="$HOME/.claude/local/bin:$HOME/.local/bin:$PATH"
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code installed:"
    print_tool_version claude
  else
    echo "Claude Code installed but 'claude' not on PATH. Try opening a new shell."
  fi
}

install_copilot_cli() {
  if command -v copilot >/dev/null 2>&1; then
    echo "GitHub Copilot CLI is already installed:"
    print_tool_version copilot
    return 0
  fi

  echo "Installing GitHub Copilot CLI..."
  npm install -g @github/copilot
  ensure_npm_global_bin_on_path
  if command -v copilot >/dev/null 2>&1; then
    echo "GitHub Copilot CLI installed:"
    print_tool_version copilot
  else
    print_path_guidance copilot
  fi
}

install_codex() {
  if command -v codex >/dev/null 2>&1; then
    echo "Codex is already installed:"
    print_tool_version codex
    return 0
  fi

  echo "Installing Codex..."
  npm install -g @openai/codex
  ensure_npm_global_bin_on_path
  if command -v codex >/dev/null 2>&1; then
    echo "Codex installed:"
    print_tool_version codex
  else
    print_path_guidance codex
  fi
}

main() {
  # Claude Code uses its native installer (no npm needed)
  install_claude_code

  # Copilot CLI and Codex require npm
  if ensure_npm; then
    ensure_npm_global_bin_on_path
    install_copilot_cli
    install_codex
  else
    echo "npm not found; skipping Copilot CLI and Codex (Claude Code installed independently)."
  fi

  echo "===================="
  echo "Installed AI tools"
  echo "===================="
  print_tool_version claude
  print_tool_version copilot
  print_tool_version codex
}

main
