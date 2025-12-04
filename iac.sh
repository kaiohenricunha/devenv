#!/usr/bin/env zsh
# iac_tools_setup.sh — installs Pulumi, tenv + Terraform / Terragrunt / OpenTofu

set -euo pipefail

export PULUMI_VERSION="3.84.0"
export TENV_VERSION="4.8.3"
export TERRAFORM_VERSION="1.14.0"
export TERRAGRUNT_VERSION="0.56.4"
export OPENTOFU_VERSION="1.7.1"

OS=$(uname -s)

install_pulumi() {
  if ! command -v pulumi >/dev/null 2>&1 || ! pulumi version | grep -q "v$PULUMI_VERSION"; then
    echo "Installing Pulumi v$PULUMI_VERSION..."
    curl -fsSL https://get.pulumi.com | sh -s -- --version $PULUMI_VERSION
    export PATH="$PATH:$HOME/.pulumi/bin"
    # if using zsh, update session
    if [[ -n "$ZSH_VERSION" ]]; then
      source ~/.zshrc || true
    fi
  else
    echo "Pulumi v$PULUMI_VERSION is already installed."
  fi
}

install_tenv() {
  if ! command -v tenv >/dev/null 2>&1; then
    echo "Installing tenv v$TENV_VERSION..."
    if [[ "$OS" == "Darwin" ]]; then
      brew install tenv
    else
      curl -fsSL -o tenv.tar.gz \
        "https://github.com/tofuutils/tenv/releases/download/v$TENV_VERSION/tenv_v${TENV_VERSION}_Linux_x86_64.tar.gz"
      tar -xzf tenv.tar.gz
      chmod +x tenv
      sudo mv tenv /usr/local/bin/
      rm tenv.tar.gz
    fi
  else
    echo "tenv already installed (assuming up-to-date or managed elsewhere)."
  fi
}

install_iac_tools_via_tenv() {
  # Terraform
  if ! command -v terraform >/dev/null 2>&1 || ! terraform version | grep -q "$TERRAFORM_VERSION"; then
    echo "Installing Terraform $TERRAFORM_VERSION via tenv..."
    tenv terraform install "$TERRAFORM_VERSION"
  else
    echo "Terraform $TERRAFORM_VERSION already installed."
  fi

  # Terragrunt
  if ! command -v terragrunt >/dev/null 2>&1 || ! terragrunt --version | grep -q "$TERRAGRUNT_VERSION"; then
    echo "Installing Terragrunt $TERRAGRUNT_VERSION via tenv..."
    tenv terragrunt install "$TERRAGRUNT_VERSION"
  else
    echo "Terragrunt $TERRAGRUNT_VERSION already installed."
  fi

  # OpenTofu
  if ! command -v tofu >/dev/null 2>&1 || ! tofu version 2>/dev/null | grep -q "$OPENTOFU_VERSION"; then
    echo "Installing OpenTofu $OPENTOFU_VERSION via tenv..."
    tenv tofu install "$OPENTOFU_VERSION"
  else
    echo "OpenTofu $OPENTOFU_VERSION already installed."
  fi
}

main() {
  install_pulumi
  install_tenv
  install_iac_tools_via_tenv

  echo "===================="
  echo "Installed IaC tools"
  echo "===================="
  pulumi version 2>/dev/null || echo "pulumi: not installed"
  tenv version 2>/dev/null || echo "tenv: not installed"
  terraform version 2>/dev/null || echo "terraform: not installed"
  terragrunt --version 2>/dev/null || echo "terragrunt: not installed"
  tofu version 2>/dev/null || echo "opentofu: not installed"
}

main
