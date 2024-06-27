#!/bin/bash

export PULUMI_VERSION="3.121.0"
export TERRAFORM_VERSION="1.8.5"
export TERRAGRUNT_VERSION="0.56.4"
export OPENTOFU_VERSION="1.7.1"
export TENV_VERSION="2.1.8"
export ANSIBLE_VERSION="10.1.0"

# --------------------------#
# Install IaC tools:
# Pulumi, Terraform, Terragrunt, Ansible, OpenTofu, Crossplane
# --------------------------#

## Pulumi

### Install Pulumi if not already installed
if ! pulumi version | grep -q "$PULUMI_VERSION"; then
    echo "Installing Pulumi v$PULUMI_VERSION..."
    curl -fsSL https://get.pulumi.com | sh -s -- --version $PULUMI_VERSION
else
    echo "Pulumi v$PULUMI_VERSION is already installed."
fi

## Install tenv if not already installed
if ! tenv version | grep -q "$TENV_VERSION"; then
    echo "Installing tenv..."
    curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${TENV_VERSION}_amd64.deb"
    sudo dpkg -i "tenv_${TENV_VERSION}_amd64.deb"
else
    echo "tenv is already installed."
fi

## Terraform

### Check if the desired Terraform version is already installed
if ! tenv tf list | grep -q "$TERRAFORM_VERSION"; then
    echo "Installing Terraform $TERRAFORM_VERSION..."
    tenv tf install $TERRAFORM_VERSION
else
    echo "Terraform $TERRAFORM_VERSION is already installed."
fi

## Terragrunt

### Check if the desired Terragrunt version is already installed
if ! tenv tg list | grep -q "$TERRAGRUNT_VERSION"; then
    echo "Installing Terragrunt $TERRAGRUNT_VERSION..."
    tenv tg install $TERRAGRUNT_VERSION
else
    echo "Terragrunt $TERRAGRUNT_VERSION is already installed."
fi

## OpenTofu

### Check if the desired OpenTofu version is already installed
if ! tenv tofu list | grep -q "$OPENTOFU_VERSION"; then
    echo "Installing OpenTofu $OPENTOFU_VERSION..."
    tenv tofu install $OPENTOFU_VERSION
else
    echo "OpenTofu $OPENTOFU_VERSION is already installed."
fi

## Ansible

### Install the desired version of Ansible if not already installed
if ! ansible --version | grep -q "$ANSIBLE_VERSION"; then
    echo "Installing Ansible v$ANSIBLE_VERSION..."
    sudo add-apt-repository --yes ppa:ansible/ansible-$ANSIBLE_VERSION
    sudo apt update
    sudo apt install -y ansible
else
    echo "Ansible v$ANSIBLE_VERSION is already installed."
fi

## Crossplane

curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh # The script detects your CPU architecture and downloads the latest stable release.

echo "===================="
echo "Installed IaC tools"
echo "===================="
tofu version
terragrunt --version
echo "pulumi: $(pulumi version)"
terraform version
ansible --version
crossplane version
