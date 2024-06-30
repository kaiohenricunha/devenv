#!/bin/zsh


# --------------------------#
# Install Kubernetes tools:
# kubectl, kubectx, kubens, Helm, Kubeshark
# --------------------------#

## Check and install kubectl
if ! command -v kubectl &>/dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
else
    echo "kubectl is already installed."
fi

## Check and install kubectx and kubens
if ! command -v kubectx &>/dev/null || ! command -v kubens &>/dev/null; then
    echo "Installing kubectx and kubens..."
    sudo git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
    sudo ln -s ~/.kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s ~/.kubectx/kubens /usr/local/bin/kubens
else
    echo "kubectx and kubens are already installed."
fi

## Check and install Helm
if ! command -v helm &>/dev/null; then
    echo "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
else
    echo "Helm is already installed."
fi

## Check and install Kubeshark
if ! ks version 2>&1 | grep -q "v52.3.68"; then
    echo "Installing Kubeshark..."
    sh <(curl -Ls https://kubeshark.co/install)
else
    echo "Kubeshark is already installed."
fi
