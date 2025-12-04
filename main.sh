#!/usr/bin/env bash

set -euo pipefail

if [[ $(uname -s) != "Linux" ]]; then
    echo "This setup script is intended to run on Linux only." >&2
    exit 1
fi

echo "Detected Linux (Pop!_OS / Ubuntu-based). Installing necessary system packages..."

sudo apt-get update
sudo apt-get install -y \
    curl git vim make binutils bison gcc build-essential wget jq htop iftop \
    tk-dev geomview tree xclip xsel shellcheck apt-transport-https \
    ca-certificates gnupg \
    zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libssl-dev \
    libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev

# --------------------------#
# Install/configure ZSH and Oh My Zsh
# --------------------------#

## Check and install ZSH and Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing ZSH and Oh My Zsh..."
    sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
else
    echo "Oh My Zsh is already installed."
fi

## Install Oh My Zsh plugins
echo "Installing Oh My Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $ZSH_CUSTOM/plugins/fast-syntax-highlighting
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete
fi

## Enable plugins by adding them to .zshrc (idempotent)
if [[ -f "$HOME/.zshrc" ]]; then
    # Only rewrite if our core plugins are not yet present
    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc" || \
       ! grep -q "vscode" "$HOME/.zshrc" || \
       ! grep -q "golang" "$HOME/.zshrc" || \
       ! grep -q "terraform" "$HOME/.zshrc" || \
       ! grep -q "kubectx" "$HOME/.zshrc" || \
       ! grep -q "operator-sdk" "$HOME/.zshrc" || \
       ! grep -q "kube-ps1" "$HOME/.zshrc"; then
        echo "Enabling plugins in .zshrc..."
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak.devenv" || true
        awk '
            BEGIN { in_plugins = 0 }
            /^plugins=\(/ {
                in_plugins = 1
                printf "plugins=(git vscode golang terraform kubectx operator-sdk kube-ps1 zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)\n"
                next
            }
            in_plugins && /\)/ {
                in_plugins = 1
                next
            }
            { print }
        ' "$HOME/.zshrc" > "$HOME/.zshrc.devenv.tmp"
        mv "$HOME/.zshrc.devenv.tmp" "$HOME/.zshrc"
    fi
fi

# Install programming languages
./programming_languages.sh

# Install IaC tools
./iac.sh

# Install cloud tools
./cloud_tools.sh

# Install k8s tools
./k8s_tools.sh

# Install other tools
./other_tools.sh

# Configure contexts and additional adjustments
./final_config.sh
