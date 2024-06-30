#!/bin/zsh

export PULUMI_VERSION="3.121.0"
export TERRAFORM_VERSION="1.9.0"
export TERRAGRUNT_VERSION="0.56.4"
export OPENTOFU_VERSION="1.7.1"
export TENV_VERSION="2.1.8"
export ANSIBLE_VERSION="10.1.0"

# Check the operating system
OS=$(uname -s)

## Pulumi

### Check if Pulumi is already installed and matches desired version
if ! command -v pulumi >/dev/null 2>&1 || ! pulumi version | grep -qF "v$PULUMI_VERSION"; then
    echo "Installing Pulumi v$PULUMI_VERSION..."
    curl -fsSL https://get.pulumi.com | sh -s -- --version $PULUMI_VERSION
    export PATH=$PATH:$HOME/.pulumi/bin
    source ~/.zshrc  # Update PATH in the current session
else
    echo "Pulumi v$PULUMI_VERSION is already installed."
fi

# Install tenv if not already installed
if ! command -v tenv >/dev/null 2>&1 || ! tenv version | grep -q "$TENV_VERSION"; then
    echo "Installing tenv..."
    if [[ "$OS" == "Darwin" ]]; then
        # macOS installation using Homebrew
        brew install tenv
    else
        # Linux installation using dpkg
        curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${TENV_VERSION}_amd64.deb"
        sudo dpkg -i "tenv_${TENV_VERSION}_amd64.deb"
    fi
else
    echo "tenv is already installed."
fi

## Terraform

### Check if the desired Terraform version is already installed
if ! command -v tf >/dev/null 2>&1 || ! tenv tf list | grep -q "$TERRAFORM_VERSION"; then
    echo "Installing Terraform $TERRAFORM_VERSION..."
    tenv tf install $TERRAFORM_VERSION
else
    echo "Terraform $TERRAFORM_VERSION is already installed."
fi

## Terragrunt

### Check if the desired Terragrunt version is already installed
if ! command -v tg >/dev/null 2>&1 || ! tenv tg list | grep -q "$TERRAGRUNT_VERSION"; then
    echo "Installing Terragrunt $TERRAGRUNT_VERSION..."
    tenv tg install $TERRAGRUNT_VERSION
else
    echo "Terragrunt $TERRAGRUNT_VERSION is already installed."
fi

## OpenTofu

### Check if the desired OpenTofu version is already installed
if ! command -v tofu >/dev/null 2>&1 || ! tenv tofu list | grep -q "$OPENTOFU_VERSION"; then
    echo "Installing OpenTofu $OPENTOFU_VERSION..."
    tenv tofu install $OPENTOFU_VERSION
else
    echo "OpenTofu $OPENTOFU_VERSION is already installed."
fi

## Ansible

# Install Ansible on macOS using pip
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v ansible >/dev/null 2>&1 || ! ansible --version | grep -q "ansible $ANSIBLE_VERSION"; then
        echo "Installing Ansible with pip..."
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        sudo python get-pip.py
        sudo pip install ansible
        rm -rf get-pip.py
    else
        echo "Ansible v$ANSIBLE_VERSION is already installed."
    fi
fi

# Install Ansible on Linux using apt (existing code)
if [[ "$OS" != "Darwin" ]]; then
    if ! command -v ansible >/dev/null 2>&1 || ! ansible --version | grep -q "ansible $ANSIBLE_VERSION"; then
        echo "Installing Ansible v$ANSIBLE_VERSION..."
        sudo add-apt-repository --yes ppa:ansible/ansible-$ANSIBLE_VERSION
        sudo apt update
        sudo apt install -y ansible
    else
        echo "Ansible v$ANSIBLE_VERSION is already installed."
    fi
fi

## Crossplane

curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh # The script detects your CPU architecture and downloads the latest stable release.
sudo mv crossplane /usr/local/bin

echo "===================="
echo "Installed IaC tools"
echo "===================="
echo "pulumi: $(pulumi version)"
tenv version
tofu version
terragrunt --version
terraform version
ansible --version
crossplane version
