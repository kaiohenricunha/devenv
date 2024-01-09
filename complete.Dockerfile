
# Setting up a more in-depth container for SRE/DevOps work
# -----------------------------------------

# k6 Stage
FROM loadimpact/k6:latest as k6-stage

# Go Stage
FROM golang:1.21.5 AS go-stage

# Python Stage
FROM python:3.9 AS python-stage

# Node.js Stage
FROM node:16 AS node-stage

# Final Stage
# ------------
FROM ubuntu:latest

# Copy k6 from the k6 stage
COPY --from=k6-stage /usr/bin/k6 /usr/bin/k6

# Copy Go and Python binaries from their respective stages
COPY --from=go-stage /usr/local/go/ /usr/local/
COPY --from=python-stage /usr/local /usr/local

# Copy Node.js binaries from the Node.js stage
COPY --from=node-stage /usr/local/bin/node /usr/local/bin/
COPY --from=node-stage /usr/local/lib/node_modules /usr/local/lib/node_modules

# Create a symbolic link for Node.js and npm
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Update and install necessary basic packages
RUN apt-get update && apt-get install -y curl git unzip wget bash-completion bison software-properties-common binutils gcc make dirmngr gnupg2 bsdmainutils jq htop iftop && \
    rm -rf /var/lib/apt/lists/*

# Kubernetes: kubectl, kubectx, kubens, Helm
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv && \
    git clone --depth=1 https://github.com/tgenv/tgenv.git ~/.tgenv && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    git clone https://github.com/ahmetb/kubectx.git ~/.kubectx && \
    ln -s ~/.kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s ~/.kubectx/kubens /usr/local/bin/kubens && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

# Set environment path for tfenv and tgenv
ENV PATH="/root/.tfenv/bin:/root/.tgenv/bin:${PATH}"

# Cloud: Terraform(tfenv), Terragrunt(tgenv), AWS CLI, GCP SDK, Azure CLI, Pulumi, and eksctl
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    curl -fsSL https://get.pulumi.com | sh && \
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# Install istioctl, kubectl-argo-rollouts, Minikube, Docker Compose, Argo CLI
RUN curl -L https://istio.io/downloadIstio | sh - && \
    mv istio-*/bin/istioctl /usr/local/bin && rm -rf istio-* && \
    curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64 && \
    chmod +x ./kubectl-argo-rollouts-linux-amd64 && mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts && \
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    chmod +x minikube && mv minikube /usr/local/bin && \
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.5.2/argo-linux-amd64.gz && \
    gunzip argo-linux-amd64.gz && \
    chmod +x argo-linux-amd64 && \
    mv ./argo-linux-amd64 /usr/local/bin/argo

# Install additional tools: htop, iftop, jq
RUN apt-get update && apt-get install -y htop iftop jq

# Verify installation in a single step
RUN node -v && npm -v && gcloud version && az version && kubectl-argo-rollouts version && docker-compose --version && helm version && istioctl version --remote=false && eksctl version && kubectl version --client && minikube version && argo version

# Set up a non-root user and set working directory
RUN useradd -m sre
USER sre
WORKDIR /home/sre

# Start bash shell
CMD ["/bin/bash"]
