#!/bin/zsh

# --------------------------#
# Install cloud tools:
# AWS CLI, Google Cloud SDK, Azure CLI, eksctl
# --------------------------#

# Check the operating system
OS=$(uname -s)

# Function to install AWS CLI
install_aws_cli() {
    if ! command -v aws >/dev/null 2>&1; then
        echo "Installing AWS CLI..."
        if [[ "$OS" == "Darwin" ]]; then
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        else
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
        fi
    else
        echo "AWS CLI is already installed."
    fi
}

# Function to install Google Cloud SDK
install_google_cloud_sdk() {
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "Installing Google Cloud SDK..."
        if [[ "$OS" == "Darwin" ]]; then
            # Determine the hardware architecture
            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz"
            else
                URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz"
            fi
            curl -O $URL
            tar -xvf google-cloud-*.tar.gz
            ./google-cloud-sdk/install.sh
            ./google-cloud-sdk/bin/gcloud init
        else
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            sudo apt-get update && sudo apt-get install google-cloud-cli -y
        fi
    else
        echo "Google Cloud SDK is already installed."
    fi
}

# Function to install Azure CLI
install_azure_cli() {
    if ! command -v az >/dev/null 2>&1; then
        echo "Installing Azure CLI..."
        if [[ "$OS" == "Darwin" ]]; then
            brew install azure-cli
        else
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        fi
    else
        echo "Azure CLI is already installed. Upgrading..."
        az upgrade
    fi
}

# Function to install eksctl
install_eksctl() {
    if ! command -v eksctl >/dev/null 2>&1; then
        echo "Installing eksctl..."
        if [[ "$OS" == "Darwin" ]]; then
            brew tap weaveworks/tap
            brew install weaveworks/tap/eksctl
        else
            curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/v0.154.0/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
            sudo mv /tmp/eksctl /usr/local/bin
        fi
    else
        echo "eksctl is already installed."
    fi
}

# Install cloud tools
install_aws_cli
install_google_cloud_sdk
install_azure_cli
install_eksctl

# Print versions
echo "===================="
echo "Installed cloud tools"
echo "===================="
aws --version
gcloud --version
az --version
echo "eksctl: $(eksctl version)"
