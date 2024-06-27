#!/bin/bash

# --------------------------#
# Install cloud tools:
# AWS CLI, Google Cloud SDK, Azure CLI, eksctl
# --------------------------#

## Install AWS CLI
if ! aws --version 2>&1 | grep -q "aws-cli"; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
else
    echo "AWS CLI is already installed."
fi

## Install Google Cloud SDK
if ! gcloud --version 2>&1 | grep -q "Google Cloud SDK"; then
    echo "Installing Google Cloud SDK..."
    GOOGLE_SDK_REPO="deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main"
    if ! grep -q "^${GOOGLE_SDK_REPO}$" /etc/apt/sources.list.d/google-cloud-sdk.list 2>/dev/null; then
        echo "${GOOGLE_SDK_REPO}" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    fi
    ## Always update the GPG key to the latest
    sudo rm -f /usr/share/keyrings/cloud.google.gpg
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    sudo apt-get update && sudo apt-get install google-cloud-sdk -y
else
    echo "Google Cloud SDK is already installed."
fi

## Install Azure CLI
if ! az --version 2>&1 | grep -q "azure-cli"; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    echo "Azure CLI is already installed. Upgrading..."
    az upgrade
fi

## Install eksctl
if ! eksctl version 2>&1 | grep -q "eksctl"; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/v0.154.0/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
else
    echo "eksctl is already installed."
fi

# Print versions
echo "===================="
echo "Installed cloud tools"
echo "===================="
aws --version
gcloud --version
az --version
echo "eksctl: $(eksctl version)"
