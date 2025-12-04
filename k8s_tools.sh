#!/usr/bin/env bash

set -euo pipefail

OS=$(uname -s)
ARCH=$(uname -m)

log() {
    printf "[k8s_tools] %s\n" "$*"
}

get_latest_github_release() {
  curl -s "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

install_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    log "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
  else
    log "kubectl already installed."
  fi
}

install_kubectx_kubens() {
  if ! command -v kubectx >/dev/null 2>&1 || ! command -v kubens >/dev/null 2>&1; then
    log "Installing kubectx + kubens..."
    KUBECTX_VERSION=$(get_latest_github_release "ahmetb/kubectx")
    
    curl -Lo kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz"
    curl -Lo kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz"
    
    tar -xzf kubectx.tar.gz kubectx
    tar -xzf kubens.tar.gz kubens
    
    chmod +x kubectx kubens
    sudo mv kubectx /usr/local/bin/kubectx
    sudo mv kubens /usr/local/bin/kubens
    
    rm kubectx.tar.gz kubens.tar.gz
  else
    log "kubectx and kubens already installed."
  fi
}

install_helm() {
  if ! command -v helm >/dev/null 2>&1; then
    log "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod +x get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
  else
    log "helm already installed."
  fi
}

install_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker "$USER"
    log "Docker installed. You may need to log out and back in for group changes to take effect."
  else
    log "Docker already installed."
  fi
}

install_minikube() {
  if ! command -v minikube >/dev/null 2>&1; then
    log "Installing minikube..."
    curl -Lo minikube-linux-amd64 https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    sudo mv minikube-linux-amd64 /usr/local/bin/minikube
  else
    log "minikube already installed."
  fi
}

install_kind() {
  if ! command -v kind >/dev/null 2>&1; then
    log "Installing kind..."
    # Get latest version dynamically
    KIND_VERSION=$(get_latest_github_release "kubernetes-sigs/kind")
    log "Latest kind version: $KIND_VERSION"
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
    chmod +x kind
    sudo mv kind /usr/local/bin/kind
  else
    log "kind already installed."
  fi
}

main() {
  install_kubectl
  install_kubectx_kubens
  install_helm
  install_docker
  install_minikube
  install_kind

  echo "===================="
  echo "Installed Kubernetes / local-cluster tools"
  echo "===================="
  
  if command -v kubectl >/dev/null 2>&1; then
      echo "kubectl: $(kubectl version --client --output=yaml | grep gitVersion | awk '{print $2}')"
  else
      echo "kubectl: not installed"
  fi

  if command -v kubectx >/dev/null 2>&1; then
      echo "kubectx: installed"
  else
      echo "kubectx: not installed"
  fi

  if command -v kubens >/dev/null 2>&1; then
      echo "kubens: installed"
  else
      echo "kubens: not installed"
  fi

  if command -v helm >/dev/null 2>&1; then
      echo "helm: $(helm version --short)"
  else
      echo "helm: not installed"
  fi

  if command -v docker >/dev/null 2>&1; then
      echo "docker: $(docker --version)"
  else
      echo "docker: not installed"
  fi

  if docker compose version >/dev/null 2>&1; then
      echo "docker compose: $(docker compose version)"
  else
      echo "docker compose: not installed"
  fi

  if command -v minikube >/dev/null 2>&1; then
      echo "minikube: $(minikube version --short 2>/dev/null || minikube version | head -n1)"
  else
      echo "minikube: not installed"
  fi

  if command -v kind >/dev/null 2>&1; then
      echo "kind: $(kind version)"
  else
      echo "kind: not installed"
  fi
}

main
