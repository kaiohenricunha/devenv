#!/usr/bin/env bash

set -euo pipefail

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

  echo "npm is required to install AI tools. Ensure Node.js/npm is installed first."
  exit 1
}

ensure_npm_global_bin_on_path() {
  local npm_global_bin=""
  npm_global_bin="$(npm prefix -g 2>/dev/null)/bin"
  if [[ -n "$npm_global_bin" && -d "$npm_global_bin" && ":$PATH:" != *":$npm_global_bin:"* ]]; then
    export PATH="$npm_global_bin:$PATH"
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

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed:"
    print_tool_version claude
    return 0
  fi

  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
  ensure_npm_global_bin_on_path
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code installed:"
    print_tool_version claude
  else
    echo "Claude Code installed but 'claude' is not on PATH in this shell. Try: export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
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
    echo "GitHub Copilot CLI installed but 'copilot' is not on PATH in this shell. Try: export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
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
    echo "Codex installed but 'codex' is not on PATH in this shell. Try: export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
  fi
}

main() {
  ensure_npm
  ensure_npm_global_bin_on_path
  install_claude_code
  install_copilot_cli
  install_codex

  echo "===================="
  echo "Installed AI tools"
  echo "===================="
  print_tool_version claude
  print_tool_version copilot
  print_tool_version codex
}

main
