#!/bin/bash

export ISTIO_VERSION="1.22.1"

# --------------------------#
# Install other tools:
# K6, Docker Compose, Minikube, Kind, Flux CLI, istioctl
# --------------------------#

## Check and install K6 for load testing
if ! k6 --version 2>&1 | grep -q "k6"; then
    echo "Installing K6..."
    sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
    sudo apt-get update
    sudo apt-get install -y k6
else
    echo "K6 is already installed."
fi

## Check and install Docker Compose
if ! docker-compose --version 2>&1 | grep -q "Docker"; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

## Check and install Minikube
if ! minikube version 2>&1 | grep -q "minikube"; then
    echo "Installing Minikube..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin
else
    echo "Minikube is already installed."
fi

## Check and install Kind
if ! kind version 2>&1 | grep -q "kind"; then
    echo "Installing Kind..."
    go install sigs.k8s.io/kind@v0.23.0
else
    echo "Kind is already installed."
fi

## Check and install istioctl
if ! istioctl version 2>&1 | grep -q "$ISTIO_VERSION"; then
    echo "Installing istioctl..."
    curl -L "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-linux-amd64.tar.gz" -o "istio-$ISTIO_VERSION.tar.gz"
    tar -xzf "istio-$ISTIO_VERSION.tar.gz"
    sudo mv "istio-$ISTIO_VERSION/bin/istioctl" /usr/local/bin/
    rm -rf "istio-$ISTIO_VERSION" "istio-$ISTIO_VERSION.tar.gz"
else
    echo "istioctl is already installed."
fi

## Check and install Flux CLI
if ! flux version 2>&1 | grep -q "flux"; then
    echo "Installing Flux CLI..."
    curl -s https://fluxcd.io/install.sh | sudo bash
else
    echo "Flux CLI is already installed."
fi

# Print versions
echo "===================="
echo "Installed tools versions"
echo "===================="
k6 version
docker-compose --version
minikube version
kind version
istioctl version
flux -v
