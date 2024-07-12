#!/bin/zsh

# Install necessary system packages based on OS
echo "Installing necessary system packages..."

# Check if we're on macOS or Ubuntu
if [[ $(uname -s) == "Darwin" ]]; then
    # macOS
    echo "Detected macOS"
    brew update && brew upgrade
    brew install curl git vim make binutils bison gcc wget jq htop iftop geomview tree xclip xsel shellcheck cosign
elif [[ $(uname -s) == "Linux" ]]; then
    # Ubuntu
    echo "Detected Ubuntu"
    sudo apt-get update
    sudo apt-get install -y curl git vim make binutils bison gcc build-essential wget jq htop iftop tk-dev geomview tree xclip xsel shellcheck apt-transport-https ca-certificates gnupg

    # Install Homebrew
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.zshrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo "Homebrew is already installed."
    fi

    # Ensure Homebrew is in the PATH
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.zshrc
fi

# --------------------------#
# Install/configure ZSH and Oh My Zsh
# --------------------------#

## Check and install ZSH and Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing ZSH and Oh My Zsh..."
    sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

## Enable plugins by adding them to .zshrc
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    echo "Enabling plugins in .zshrc..."
    sed -i.bak 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' ~/.zshrc
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
