#!/bin/bash

# Prevent script from running as root
if [ "$(id -u)" == "0" ]; then
    echo "This script should not be run as root or using sudo. Exiting."
    exit 1
fi

# Install necessary system packages
echo "Installing necessary system packages..."
sudo apt-get update
sudo apt-get install -y curl git make binutils bison gcc build-essential libssl-dev zlib1g-dev \
                        libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev \
                        xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev jq \
                        htop iftop tk-dev geomview tree xclip xsel shellcheck

sudo snap install code --classic

# Install programming languages
./programming_languages.sh

# Install IaC tools
./iac.sh

# Install cloud tools
./cloud_tools.sh

# Install k8s tools
./k8s_tools.sh

# Install other tools
./other_tools.sh

# Configure contexts and additional adjustments
./final_config.sh
