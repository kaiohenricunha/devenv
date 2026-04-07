#!/usr/bin/env bash

set -euo pipefail

DEVENV_SCRIPT_NAME="k8s_tools"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

OS=$(uname -s)
ARCH=$(uname -m)
DEVENV_ARCH="$(detect_arch)"

install_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    log "Installing kubectl..."
    curl --retry 3 --max-time 60 -LO "https://dl.k8s.io/release/$(curl --retry 3 --max-time 15 -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${DEVENV_ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
  else
    log "kubectl already installed."
  fi
}

install_krew() {
  # Krew is a kubectl plugin manager. It installs into ~/.krew by default.
  # Idempotent detection: either kubectl krew works or the krew binary exists.
  local krew_bin="$HOME/.krew/bin/kubectl-krew"
  local path_line='export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'

  if [[ -x "$krew_bin" ]] || (command -v kubectl >/dev/null 2>&1 && kubectl krew version >/dev/null 2>&1); then
    log "krew already installed."
  else
    log "Installing krew (kubectl plugin manager)..."

    local os krew tmpdir
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"

    krew="krew-${os}_${DEVENV_ARCH}"
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN

    (
      cd "$tmpdir"
      curl --retry 3 --max-time 60 -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew}.tar.gz"
      tar -xzf "${krew}.tar.gz"
      ./${krew} install krew
    )
  fi

  # Ensure PATH is set for current script run (so subsequent steps can use kubectl krew).
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

  # Persist PATH change for interactive shells without overwriting user config.
  append_once_to_file "$HOME/.zshrc" "$path_line"
  append_once_to_file "$HOME/.bashrc" "$path_line"

  log "NOTE: open a new shell (or re-login) for krew PATH to apply everywhere."
}

install_kubectx_kubens() {
  if ! command -v kubectx >/dev/null 2>&1 || ! command -v kubens >/dev/null 2>&1; then
    log "Installing kubectx + kubens..."
    KUBECTX_VERSION=$(get_latest_github_release "ahmetb/kubectx")
    
    local kubectx_arch
    if [[ "$DEVENV_ARCH" == "amd64" ]]; then kubectx_arch="linux_x86_64"; else kubectx_arch="linux_arm64"; fi
    curl --retry 3 --max-time 60 -Lo kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_${kubectx_arch}.tar.gz"
    curl --retry 3 --max-time 60 -Lo kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_${kubectx_arch}.tar.gz"
    
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
    curl --retry 3 --max-time 60 -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
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
    sudo curl --retry 3 --max-time 60 -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
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
    local minikube_bin="minikube-linux-${DEVENV_ARCH}"
    curl --retry 3 --max-time 60 -Lo "$minikube_bin" "https://github.com/kubernetes/minikube/releases/latest/download/${minikube_bin}"
    chmod +x "$minikube_bin"
    sudo mv "$minikube_bin" /usr/local/bin/minikube
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
    curl --retry 3 --max-time 60 -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${DEVENV_ARCH}"
    chmod +x kind
    sudo mv kind /usr/local/bin/kind
  else
    log "kind already installed."
  fi
}

install_lens() {
  # Lens on Ubuntu/Pop!_OS is commonly distributed via Snap as "kontena-lens".
  # Keep this idempotent and avoid writing repo-local binaries.
  if command -v kontena-lens >/dev/null 2>&1; then
    log "Lens (kontena-lens) already installed."
    return 0
  fi

  if ! command -v snap >/dev/null 2>&1; then
    log "Installing snapd (required for Lens)..."
    sudo apt-get update
    sudo apt-get install -y snapd
    # Ensure snap is usable on systems where it's socket-activated.
    sudo systemctl enable --now snapd.socket >/dev/null 2>&1 || true
  fi

  if snap list kontena-lens >/dev/null 2>&1; then
    log "Lens (kontena-lens) already installed (snap)."
    return 0
  fi

  log "Installing Lens (kontena-lens) via snap..."
  sudo snap install kontena-lens --classic
}

main() {
  install_kubectl
  install_krew
  install_kubectx_kubens
  install_helm
  install_docker
  install_minikube
  install_kind
  install_lens

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

    if [[ -x "$HOME/.krew/bin/kubectl-krew" ]] || (command -v kubectl >/dev/null 2>&1 && kubectl krew version >/dev/null 2>&1); then
      echo "krew: installed"
    else
      echo "krew: not installed"
    fi

    if command -v kontena-lens >/dev/null 2>&1; then
      echo "lens: installed (kontena-lens)"
    else
      echo "lens: not installed"
    fi
}

main
