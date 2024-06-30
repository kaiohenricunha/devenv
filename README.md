# Linux Environment Setup for DevOps and SRE

## Overview

This repository contains scripts to set up a Linux environment tailored for Platform Engineering an Developer tasks. It automates the installation of programming languages, infrastructure-as-code (IaC) tools, cloud tools, Kubernetes tools, and other utilities commonly used in these workflows.

## Prerequisites

- A Linux-based system (tested on Ubuntu) or macOS.
- Basic familiarity with running shell scripts

## Getting Started

Clone this repository and navigate to it:

```bash
git clone git@github.com:kaiohenricunha/devenv.git
cd devenv
```

## Running the Setup

To set up your environment, run the main script:

```sh
./main.sh
```

You may need to change the repository permissions:

```bash
chmod +x *.sh
```

This script installs necessary system packages and sets up various tools and configurations specified in separate scripts for each category.

## Included Tools

- Programming Languages: Python, Go, Node.js, Rust, Java, Maven
- Infrastructure-as-Code (IaC) Tools: Pulumi, Terraform, Terragrunt, Ansible, OpenTofu and Crossplane
- Cloud Tools: AWS CLI, Google Cloud SDK, Azure CLI, eksctl
- Kubernetes Tools: kubectl, kubectx, kubens, Helm, Kubeshark
- Other Tools: K6, Docker Compose, Minikube, Kind, Flux CLI, istioctl, version managers for all programming languages.

## Configuring Environments

The setup script also configures AWS CLI profiles and updates kubeconfig files for different Kubernetes clusters.

```sh
# Configure AWS CLI
aws configure set default.region us-east-1

# Update kubeconfig for EKS-Management
aws eks update-kubeconfig --region us-east-1 --name EKS-Management ...

# Update kubeconfig for other clusters...
```

## Contributing

Contributions to this repository are welcome. If you have suggestions or improvements, feel free to open an issue or pull request.
