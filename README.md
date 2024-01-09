# Docker SRE and DevOps Container Environments

## Overview
This repository contains Dockerfiles for creating containerized environments tailored for Site Reliability Engineering (SRE) and DevOps tasks. There are two configurations available:

1. **Trimmed Environment:** This configuration includes a set of commonly used tools, making it lightweight and quick to deploy. It's ideal for everyday tasks and for users who require a basic set of tools.

2. **Complete Environment:** This setup includes a more comprehensive suite of tools, covering a wide range of SRE and DevOps needs. It's designed for in-depth tasks and advanced users who need an extensive array of utilities.

Both environments are built on top of an Ubuntu base image and include tools for managing and deploying infrastructure, such as Kubernetes (kubectl, kubectx, kubens), Terraform (via tfenv), Terragrunt (via tgenv), AWS CLI, and Helm.

## Prerequisites
- Docker installed on your machine.
- Basic knowledge of Docker commands.

## Building the Environments

### Trimmed Environment
To build the trimmed version of the environment, use the following command:

```bash
docker build -t sre-env-trimmed -f trimmed.Dockerfile .
```

### Complete Environment

To build the complete version of the environment, use the following command:

```bash
docker build -t sre-env-complete -f complete.Dockerfile .
```

Note: Replace complete.Dockerfile with the actual filename of the complete environment Dockerfile.

## Running the Environments

### Basic Run

This command runs the container in interactive mode and attaches a terminal to it.

```bash
docker run -it --name sre-lab sre-env-trimmed
```

### With AWS and Kubernetes Configurations

To mount your AWS and Kubernetes configurations from your host into the container, use the following command:

```bash
docker run -it --name sre-lab \
    -v ~/.aws:/home/sre/.aws \
    -v ~/.kube:/home/sre/.kube \
    sre-env-trimmed
```

Note: Adjust the paths if your configuration files are located elsewhere.

## Customized Run

You can customize the run command according to your needs. For example, to run the complete environment and mount specific directories, you can use:

```bash
docker run -it --name sre-lab \
    -v /path/to/your/.aws:/home/sre/.aws \
    -v /path/to/your/.kube:/home/sre/.kube \
    sre-env-complete
```

Replace `/path/to/your/` with the actual path to your .aws and .kube directories.

## Contributing

Contributions to this repository are welcome.
