#!/bin/zsh

# Install necessary system packages based on OS
echo "Installing necessary system packages..."

# Check if we're on macOS or Ubuntu
if [[ $(uname -s) == "Darwin" ]]; then
    # macOS
    echo "Detected macOS"
    brew update && brew upgrade
    brew install curl git vim make binutils bison gcc wget jq htop iftop geomview tree xclip xsel shellcheck cosign
elif [[ $(uname -s) == "Linux" ]]; then
    # Ubuntu
    echo "Detected Ubuntu"
    sudo apt-get update
    sudo apt-get install -y curl git vim make binutils bison gcc build-essential wget jq htop iftop tk-dev geomview tree xclip xsel shellcheck apt-transport-https ca-certificates gnupg
else
    echo "Unsupported operating system. Exiting."
    exit 1
fi

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
