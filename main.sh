#!/usr/bin/env bash

set -euo pipefail

DEVENV_SCRIPT_NAME="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DEVENV_TMPFILES=()
cleanup_tmpfiles() { rm -f "${DEVENV_TMPFILES[@]}" 2>/dev/null || true; }
trap cleanup_tmpfiles EXIT

DESIRED_ZSH_PLUGINS='plugins=(git vscode golang terraform kubectx operator-sdk kube-ps1 zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)'

ensure_apt_packages() {
    sudo apt-get update
    sudo apt-get install -y "$@"
}

ensure_zsh() {
    if command -v zsh >/dev/null 2>&1 && [[ -x /usr/bin/zsh ]]; then
        return 0
    fi

    log "Ensuring Zsh is installed (required by Kitty/Oh My Zsh)..."
    ensure_apt_packages zsh

    if command -v zsh >/dev/null 2>&1 && [[ ! -x /usr/bin/zsh ]]; then
        # Some systems might place zsh elsewhere; ensure Kitty's configured path exists.
        local zsh_path
        zsh_path="$(command -v zsh)"
        if [[ -x "$zsh_path" ]]; then
            log "Creating /usr/bin/zsh symlink to $zsh_path"
            sudo ln -sf "$zsh_path" /usr/bin/zsh
        fi
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        echo "ERROR: zsh is not on PATH after installation attempt." >&2
        return 1
    fi
    if [[ ! -x /usr/bin/zsh ]]; then
        echo "ERROR: /usr/bin/zsh is still missing or not executable." >&2
        return 1
    fi
}

maybe_make_kitty_safe() {
    # Goal: avoid Kitty failing hard if its configured shell is missing.
    # Only touches kitty.conf if Zsh is *still* missing.
    if [[ -x /usr/bin/zsh ]]; then
        return 0
    fi

    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    if [[ ! -f "$kitty_conf" ]]; then
        return 0
    fi

    # Conservative behavior: only change kitty.conf if it explicitly sets shell to zsh.
    if ! grep -Eq '^[[:space:]]*shell[[:space:]]+(/usr/bin/zsh|zsh)([[:space:]]|$)' "$kitty_conf"; then
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    DEVENV_TMPFILES+=("$tmp")

    awk '
        # Replace any explicit zsh shell setting with bash.
        /^[[:space:]]*shell[[:space:]]+\/usr\/bin\/zsh([[:space:]]|$)/ { print "shell /bin/bash"; next }
        /^[[:space:]]*shell[[:space:]]+zsh([[:space:]]|$)/ { print "shell /bin/bash"; next }
        { print }
    ' "$kitty_conf" >"$tmp"

    if cmp -s "$kitty_conf" "$tmp"; then
        rm -f "$tmp"
        return 0
    fi

    log "Zsh missing; updating Kitty to use /bin/bash (backup created)"
    cp "$kitty_conf" "$kitty_conf.bak.devenv" || true
    mv "$tmp" "$kitty_conf"
}

update_zshrc_plugins() {
    local zshrc="$HOME/.zshrc"
    if [[ ! -f "$zshrc" ]]; then
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    DEVENV_TMPFILES+=("$tmp")

    awk -v desired_plugins="$DESIRED_ZSH_PLUGINS" '
        BEGIN {
            inserted = 0
            skipping = 0
            saw_plugins = 0
        }

        # Start of plugins block (single-line or multi-line)
        /^[[:space:]]*plugins=\(/ {
            saw_plugins = 1
            if (inserted == 0) {
                print desired_plugins
                inserted = 1
            }
            # If this line also closes the block, do not enter skipping state.
            if ($0 ~ /\)[[:space:]]*$/) {
                skipping = 0
            } else {
                skipping = 1
            }
            next
        }

        # Skip the remainder of a multi-line plugins block until closing paren line.
        skipping {
            if ($0 ~ /^[[:space:]]*\)[[:space:]]*$/) {
                skipping = 0
            }
            next
        }

        # If no plugins block exists, insert after the ZSH=... line.
        /^[[:space:]]*ZSH=/ {
            print
            if (inserted == 0 && saw_plugins == 0) {
                print desired_plugins
                inserted = 1
            }
            next
        }

        { print }

        END {
            if (inserted == 0) {
                print desired_plugins
            }
        }
    ' "$zshrc" >"$tmp"

    if cmp -s "$zshrc" "$tmp"; then
        rm -f "$tmp"
        return 0
    fi

    log "Updating .zshrc plugins block (backup created)"
    cp "$zshrc" "$zshrc.bak.devenv" || true
    mv "$tmp" "$zshrc"
}

final_sanity_summary() {
    log "Sanity summary:"

    if command -v zsh >/dev/null 2>&1; then
        log "- zsh on PATH: $(command -v zsh)"
    else
        log "- zsh on PATH: MISSING"
    fi

    if [[ -x /usr/bin/zsh ]]; then
        log "- /usr/bin/zsh: present"
    else
        log "- /usr/bin/zsh: MISSING (Kitty may fail if configured to use it)"
        log "  Fix: sudo apt-get install -y zsh"
    fi

    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    if [[ -f "$kitty_conf" ]]; then
        local kitty_shell
        kitty_shell="$(grep -E '^[[:space:]]*shell[[:space:]]+' "$kitty_conf" | tail -n 1 || true)"
        if [[ -n "$kitty_shell" ]]; then
            log "- kitty shell: ${kitty_shell}"
        else
            log "- kitty shell: (not set in kitty.conf)"
        fi
    else
        log "- kitty.conf: not found (skipping)"
    fi
}

if [[ $(uname -s) != "Linux" ]]; then
    echo "This setup script is intended to run on Linux only." >&2
    exit 1
fi

log "Running pre-flight checks..."
check_internet
require_commands curl git sudo
log "Pre-flight checks passed."

log "Detected Linux (Pop!_OS / Ubuntu-based). Installing necessary system packages..."

ensure_apt_packages \
    curl git vim make binutils bison gcc build-essential wget jq htop iftop \
    tk-dev geomview tree xclip xsel shellcheck apt-transport-https \
    ca-certificates gnupg \
    zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libssl-dev \
    libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev

# --------------------------#
# Install/configure ZSH and Oh My Zsh
# --------------------------#

## Always ensure ZSH exists (do NOT treat ~/.oh-my-zsh as a proxy).
ensure_zsh

## Oh My Zsh install (independent of Zsh verification above)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh..."
    # Non-interactive install; do not auto-run zsh or auto-change shell.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl --retry 3 --max-time 60 -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
else
    log "Oh My Zsh is already installed."
fi

## Install Oh My Zsh plugins
log "Installing Oh My Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
fi

## Enable plugins by updating the plugins=(...) block safely + idempotently
update_zshrc_plugins

## If Zsh is still missing for any reason, avoid Kitty breaking hard.
maybe_make_kitty_safe

# ---------------------------------------------------------------------------
# Run each module via run_stage (tracks success/failure for summary)
# ---------------------------------------------------------------------------

run_stage "Programming Languages" "$SCRIPT_DIR/programming_languages.sh"
run_stage "IaC Tools"             "$SCRIPT_DIR/iac.sh"
run_stage "Cloud Tools"           "$SCRIPT_DIR/cloud_tools.sh"
run_stage "Kubernetes Tools"      "$SCRIPT_DIR/k8s_tools.sh"

# AI tools — Claude Code uses native installer; Copilot/Codex need npm (handled internally)
if ! command -v npm >/dev/null 2>&1; then
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        # shellcheck disable=SC1091
        . "$HOME/.nvm/nvm.sh"
        nvm use default >/dev/null 2>&1 || true
    fi
fi
run_stage "AI Tools" "$SCRIPT_DIR/ai_tools.sh"

run_stage "Other Tools" "$SCRIPT_DIR/other_tools.sh"

if [[ -x "$SCRIPT_DIR/virtualization.sh" ]]; then
    run_stage "Virtualization" "$SCRIPT_DIR/virtualization.sh"
fi

run_stage "Final Config" "$SCRIPT_DIR/final_config.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

final_sanity_summary
print_summary
