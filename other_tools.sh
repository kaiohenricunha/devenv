#!/bin/zsh

# --------------------------#
# Install/configure other tools:
# K6, Docker Compose, Minikube
# Kind, Flux CLI, istioctl, zsh
# --------------------------#

## Check and install K6 for load testing
if ! k6 --version 2>&1 | grep -q "k6"; then
    if [[ "$OS" == "Darwin" ]]; then
        brew install k6
    else
        echo "Installing K6..."
        sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
        echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
        sudo apt-get update
        sudo apt-get install -y k6
    fi
else
    echo "K6 is already installed."
fi

## Check and install Docker Compose
if ! docker-compose --version 2>&1 | grep -q "Docker"; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

## Check and install Minikube
if ! minikube version 2>&1 | grep -q "minikube"; then
    echo "Installing Minikube..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin
else
    echo "Minikube is already installed."
fi

## Check and install Kind
if ! kind --version 2>&1 | grep -q "kind"; then
    echo "Installing Kind..."
    go install sigs.k8s.io/kind@v0.23.0
else
    echo "Kind is already installed."
fi

## Check and install istioctl
if ! istioctl version 2>&1 | grep -q ""; then
    echo "Installing istioctl..."
    curl -sL https://istio.io/downloadIstioctl | sh -
    export PATH=$HOME/.istioctl/bin:$PATH
else
    echo "istioctl is already installed."
fi

## Check and install Flux CLI
if ! flux -v 2>&1 | grep -q "flux"; then
    echo "Installing Flux CLI..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install fluxcd/tap/flux
    else
        curl -s https://fluxcd.io/install.sh | sudo bash
    fi
else
    echo "Flux CLI is already installed."
fi

## Install aichat
brew install aichat

## Install ZSH and Oh My Zsh
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

# Print versions
echo "===================="
echo "Installed tools versions"
echo "===================="
k6 version
docker-compose --version
minikube version
kind --version
istioctl version
flux -v
aichat -V
