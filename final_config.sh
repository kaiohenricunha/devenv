#!/usr/bin/env bash

set -euo pipefail

DEVENV_SCRIPT_NAME="final_config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# # Configure AWS CLI
# echo "Configuring AWS CLI..."
# aws configure set default.region us-east-1

# # Configure AWS CLI
# aws configure set default.region us-east-1

# # Update kubeconfig for EKS-Management
# aws eks update-kubeconfig --region us-east-1 --name EKS-Management ...

# # Update kubeconfig for other clusters...

# echo "Kubernetes context setup complete."

## Reminder to restart the shell or environment
echo "Please restart your shell or source the appropriate config file to use the updated environment."
