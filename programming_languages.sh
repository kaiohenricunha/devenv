#!/usr/bin/env bash

set -euo pipefail

# Fixed versions to install
PYTHON_VERSION="3.13.0"
NODE_VERSION="22"          # major is enough for nvm
GO_VERSION="go1.25.3"
GO_BOOTSTRAP_VERSION="go1.22.6"  # used only for initial gvm bootstrap
RUST_VERSION="1.82.0"

log() {
    printf "[programming_languages] %s\n" "$*"
}

append_once_to_zshrc() {
    local line="$1"
    if [[ -f "$HOME/.zshrc" ]] && grep -Fqx "$line" "$HOME/.zshrc"; then
        return 0
    fi
    echo "$line" >>"$HOME/.zshrc"
}

install_pyenv() {
    if command -v pyenv >/dev/null 2>&1; then
        log "pyenv already in PATH."
    elif [[ -d "$HOME/.pyenv" ]]; then
        log "~/.pyenv exists; wiring into PATH."
    else
        log "Installing pyenv..."
        curl -fsSL https://pyenv.run | bash
    fi

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    append_once_to_zshrc 'export PYENV_ROOT="$HOME/.pyenv"'
    append_once_to_zshrc 'export PATH="$PYENV_ROOT/bin:$PATH"'
    append_once_to_zshrc 'eval "$(pyenv init --path)"'
    append_once_to_zshrc 'eval "$(pyenv init -)"'

    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
    fi
}

install_python() {
    if ! command -v pyenv >/dev/null 2>&1; then
        log "pyenv not available; skipping Python."
        return 0
    fi

    if ! pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
        log "Installing Python $PYTHON_VERSION via pyenv..."
        if ! pyenv install "$PYTHON_VERSION"; then
            log "WARNING: failed to install Python $PYTHON_VERSION; continuing."
            return 0
        fi
    else
        log "Python $PYTHON_VERSION already installed in pyenv."
    fi

    if pyenv global "$PYTHON_VERSION"; then
        python -m ensurepip --upgrade || true
    else
        log "WARNING: could not set global Python $PYTHON_VERSION."
    fi
}

install_gvm_and_go() {
    log "Installing gvm and Go..."

    if [[ ! -d "$HOME/.gvm" ]]; then
        log "Installing gvm..."
        if ! curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash; then
            log "WARNING: gvm installer failed; skipping Go."
            return 0
        fi
        append_once_to_zshrc '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"'
    else
        log "gvm already present."
    fi

    if [[ ! -s "$HOME/.gvm/scripts/gvm" ]]; then
        log "GVM scripts missing; skipping Go."
        return 0
    fi

    # Run gvm in a subshell with relaxed settings so its internals
    # (which reference ZSH_VERSION/GVM_DEBUG) don't break this script.
    (
        set +euo pipefail
        : "${ZSH_VERSION:=}"
        : "${GVM_DEBUG:=}"
        # shellcheck disable=SC1090
        source "$HOME/.gvm/scripts/gvm" || exit 0

        if ! gvm list 2>/dev/null | grep -Fxq "$GO_BOOTSTRAP_VERSION"; then
            echo "[programming_languages] Installing Go bootstrap $GO_BOOTSTRAP_VERSION..."
            gvm install "$GO_BOOTSTRAP_VERSION" -B || true
        else
            echo "[programming_languages] Bootstrap $GO_BOOTSTRAP_VERSION already installed."
        fi

        gvm use "$GO_BOOTSTRAP_VERSION" --default || true
        export GOROOT_BOOTSTRAP="${GOROOT:-}"

        if ! gvm list 2>/dev/null | grep -Fxq "$GO_VERSION"; then
            echo "[programming_languages] Installing Go $GO_VERSION..."
            gvm install "$GO_VERSION" || true
        else
            echo "[programming_languages] Go $GO_VERSION already installed."
        fi

        gvm use "$GO_VERSION" --default || true
    ) || true
}

install_nvm_and_node() {
    export NVM_DIR="$HOME/.nvm"

    if [[ ! -s "$NVM_DIR/nvm.sh" ]] && ! command -v nvm >/dev/null 2>&1; then
        log "Installing nvm..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi

    append_once_to_zshrc 'export NVM_DIR="$HOME/.nvm"'
    append_once_to_zshrc '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

    # Run nvm in a subshell to avoid set -u issues
    (
        set +euo pipefail
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            # shellcheck disable=SC1090
            . "$NVM_DIR/nvm.sh"
        else
            log "nvm.sh not found; skipping Node."
            exit 0
        fi

        if nvm list | grep -q "v$NODE_VERSION"; then
            log "Node.js $NODE_VERSION already installed."
        else
            log "Installing Node.js $NODE_VERSION via nvm..."
            nvm install "$NODE_VERSION"
        fi

        nvm alias default "$NODE_VERSION" || true
    )
}

install_rust() {
    if ! command -v rustup >/dev/null 2>&1 && ! command -v rustc >/dev/null 2>&1; then
        log "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
        append_once_to_zshrc 'export PATH="$HOME/.cargo/bin:$PATH"'
    fi

    export PATH="$HOME/.cargo/bin:$PATH"

    if ! command -v rustup >/dev/null 2>&1; then
        log "rustup not available; skipping Rust."
        return 0
    fi

    if rustc --version 2>/dev/null | grep -q "$RUST_VERSION"; then
        log "Rust $RUST_VERSION already active."
    else
        log "Installing Rust $RUST_VERSION via rustup..."
        rustup toolchain install "$RUST_VERSION"
        rustup default "$RUST_VERSION"
    fi
}

main() {
    install_pyenv
    install_python
    install_gvm_and_go
    install_nvm_and_node
    install_rust
}

main

echo "===================="
echo "Installed languages"
echo "===================="
command -v python &>/dev/null && python --version || echo "python: not available"
command -v go &>/dev/null && go version || echo "go: not available"
command -v node &>/dev/null && echo "node: $(node --version)" || echo "node: not available"
command -v rustc &>/dev/null && rustc --version || echo "rustc: not available"
command -v cargo &>/dev/null && cargo --version || echo "cargo: not available"
