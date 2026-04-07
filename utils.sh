#!/usr/bin/env bash
# utils.sh — shared utilities for devenv bootstrap scripts
# Source this file at the top of every script after set -euo pipefail.
# Set DEVENV_SCRIPT_NAME before sourcing to customise the log prefix.

# Guard against double-sourcing
[[ -n "${_DEVENV_UTILS_LOADED:-}" ]] && return 0
_DEVENV_UTILS_LOADED=1

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

DEVENV_LOG_FILE="${DEVENV_LOG_FILE:-/tmp/devenv-$(date +%Y%m%d-%H%M%S).log}"

log() {
  printf "[%s] %s\n" "${DEVENV_SCRIPT_NAME:-devenv}" "$*" | tee -a "$DEVENV_LOG_FILE"
}

# ---------------------------------------------------------------------------
# File helpers
# ---------------------------------------------------------------------------

append_once_to_file() {
  local file="$1" line="$2"
  [[ -f "$file" ]] || return 0
  grep -Fqx "$line" "$file" && return 0
  printf '\n%s\n' "$line" >>"$file"
}

append_once_to_zshrc() {
  append_once_to_file "$HOME/.zshrc" "$1"
}

# ---------------------------------------------------------------------------
# Architecture detection
# ---------------------------------------------------------------------------

detect_arch() {
  local machine
  machine="$(uname -m)"
  case "$machine" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    *)
      log "ERROR: Unsupported architecture: $machine"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# GitHub helpers
# ---------------------------------------------------------------------------

get_latest_github_release() {
  local repo="$1"
  local tag
  tag="$(curl --retry 3 --retry-delay 2 --max-time 15 -fsSL \
    "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r '.tag_name // empty')"
  if [[ -z "$tag" ]]; then
    log "ERROR: Failed to fetch latest release for ${repo}"
    return 1
  fi
  echo "$tag"
}

# ---------------------------------------------------------------------------
# WSL detection
# ---------------------------------------------------------------------------

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSL_INTEROP:-}" ]] || grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

require_commands() {
  local missing=()
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    log "ERROR: Required commands not found: ${missing[*]}"
    return 1
  fi
}

check_internet() {
  if ! curl --max-time 5 -fsSL -o /dev/null https://github.com 2>/dev/null; then
    log "ERROR: No internet connectivity (could not reach github.com)"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Stage orchestration (used by main.sh)
# ---------------------------------------------------------------------------

declare -a DEVENV_SUCCEEDED=()
declare -a DEVENV_FAILED=()

run_stage() {
  local name="$1" script="$2"
  log "=== Starting: $name ==="
  if "$script"; then
    DEVENV_SUCCEEDED+=("$name")
    log "=== Completed: $name ==="
  else
    DEVENV_FAILED+=("$name")
    log "WARNING: $name failed (continuing)"
  fi
}

print_summary() {
  echo ""
  echo "============================="
  echo "  devenv Setup Summary"
  echo "============================="
  if (( ${#DEVENV_SUCCEEDED[@]} > 0 )); then
    echo "SUCCEEDED:"
    for s in "${DEVENV_SUCCEEDED[@]}"; do echo "  + $s"; done
  fi
  if (( ${#DEVENV_FAILED[@]} > 0 )); then
    echo "FAILED:"
    for f in "${DEVENV_FAILED[@]}"; do echo "  - $f"; done
  fi
  echo ""
  echo "Full log: $DEVENV_LOG_FILE"
}
