#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script supports only Linux. Detected: $(uname -s). Aborting."
  exit 1
fi

ensure_npm() {
  if command -v npm >/dev/null 2>&1; then
    return 0
  fi

  echo "npm is required to install AI tools. Ensure Node.js/npm is installed first."
  exit 1
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed: $(claude --version)"
    return 0
  fi

  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
  echo "Claude Code installed: $(claude --version)"
}

install_copilot_cli() {
  if command -v copilot >/dev/null 2>&1; then
    echo "GitHub Copilot CLI is already installed: $(copilot --version)"
    return 0
  fi

  echo "Installing GitHub Copilot CLI..."
  npm install -g @github/copilot
  echo "GitHub Copilot CLI installed: $(copilot --version)"
}

install_codex() {
  if command -v codex >/dev/null 2>&1; then
    echo "Codex is already installed: $(codex --version)"
    return 0
  fi

  echo "Installing Codex..."
  npm install -g @openai/codex
  echo "Codex installed: $(codex --version)"
}

main() {
  ensure_npm
  install_claude_code
  install_copilot_cli
  install_codex

  echo "===================="
  echo "Installed AI tools"
  echo "===================="
  claude --version || echo "claude: not installed"
  copilot --version || echo "copilot: not installed"
  codex --version || echo "codex: not installed"
}

main
