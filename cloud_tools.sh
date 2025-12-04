#!/usr/bin/env zsh

set -euo pipefail

OS=$(uname -s)

install_aws_cli() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "Installing AWS CLI v2..."
    if [[ "$OS" == "Darwin" ]]; then
      curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
      sudo installer -pkg AWSCLIV2.pkg -target /
      rm AWSCLIV2.pkg
    else
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip -o awscliv2.zip
      sudo ./aws/install --update  # --update ensures idempotency
      rm -rf awscliv2.zip aws/
    fi
  else
    echo "AWS CLI already installed: $(aws --version)"
  fi
}

install_gcloud_cli() {
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "Installing Google Cloud SDK (gcloud)..."
    # Use apt install on Debian/Ubuntu (assuming Linux), else fallback to tarball
    if [[ "$OS" != "Darwin" ]]; then
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
      sudo apt-get update -y
      sudo apt-get install -y google-cloud-cli
    else
      echo "Please install gcloud manually on macOS."
    fi
  else
    echo "gcloud CLI already installed: $(gcloud version --format 'value(core.version)')"
  fi
}

install_azure_cli() {
  if ! command -v az >/null 2>&1; then
    echo "Installing Azure CLI..."
    if [[ "$OS" == "Darwin" ]]; then
      brew install azure-cli
    else
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
  else
    echo "Azure CLI already installed: $(az version | head -n1)"
  fi
}

main() {
  install_aws_cli
  install_gcloud_cli
  install_azure_cli

  echo "===================="
  echo "Installed cloud tools"
  echo "===================="
  aws --version || echo "aws: not installed"
  gcloud version || echo "gcloud: not installed"
  az --version || echo "az: not installed"
}

main
