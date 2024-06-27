#!/bin/bash

export PYTHON_VERSION="3.11.4"
export NODE_VERSION="20"
export JAVA_VERSION="openjdk@1.17.0"
export GO_VERSION="go1.22.2"
export RUST_VERSION="1.79.0"
export MAVEN_VERSION="3.8.8"

# --------------------------#
# Install programming languages:
# Python, Go, Node, Rust, Java, Maven
# --------------------------#

## Python

### Install pyenv if not already installed
if ! command -v pyenv &>/dev/null; then
    echo "Installing pyenv..."
    curl https://pyenv.run | bash
    echo "pyenv installed successfully."

    echo "Configuring pyenv shell for Zsh"
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc

    source ~/.zshrc
else
    echo "pyenv is already installed."
fi

### Check if the desired Python version is already installed and used
if pyenv versions --bare | grep -q "^$PYTHON_VERSION\$"; then
    echo "Python $PYTHON_VERSION is already installed."
else
    echo "Installing Python $PYTHON_VERSION"
    pyenv install $PYTHON_VERSION
    echo "Python installed successfully."
fi

### Set the specified Python version as global
pyenv global $PYTHON_VERSION
python -m ensurepip --upgrade

## Go

### Install GVM and Go
if [ ! -d "$HOME/.gvm" ]; then
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

    source $HOME/.gvm/scripts/gvm || {
        echo "Failed to source GVM scripts."
        exit 1
    }

    ### Install and use a Go version for bootstrap
    gvm install go1.20.6 -B
    gvm use go1.20.6
    export GOROOT_BOOTSTRAP=$GOROOT

    ### Install target version of Go
    gvm install $GO_VERSION
else
    source $HOME/.gvm/scripts/gvm
fi

if gvm list | grep -q "$GO_VERSION"; then
    echo "Go $GO_VERSION is already installed."
else
    gvm install $GO_VERSION
fi

gvm use $GO_VERSION --default

## Node

### Install Node.js using NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
if ! command -v nvm &>/dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    source $NVM_DIR/nvm.sh  # Ensure the nvm command is available
else
    echo "NVM is already installed."
    source $NVM_DIR/nvm.sh
fi

### Check if the desired Node.js version is already installed
if nvm list | grep -q "v$NODE_VERSION"; then
    echo "Node.js $NODE_VERSION is already installed."
else
    nvm install $NODE_VERSION
    echo "Node.js $NODE_VERSION installed successfully."
fi

### Use the specified Node.js version
nvm use $NODE_VERSION

## Rust

### Check if rustup is installed and if the desired Rust version is active
if ! command -v rustc &>/dev/null; then
    echo "Installing rustup..."
    sudo apt update
    sudo apt install -y rustup
    rustup default stable
    rustup update
    echo "export PATH=\"$HOME/.cargo/bin:\$PATH\"" >> ~/.zshrc
    source ~/.zshrc
else
    echo "Rust is already installed."
fi

### Check if the desired Rust version is already installed and set as default
if rustc --version | grep -q "$RUST_VERSION"; then
    echo "Rust $RUST_VERSION is already installed and set as default."
else
    echo "Installing Rust version $RUST_VERSION"
    rustup toolchain install $RUST_VERSION
    rustup default $RUST_VERSION
fi

## Java

### Check if Jabba is installed
if ! command -v jabba &>/dev/null; then
    echo "Installing Jabba..."
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash
    echo "source $HOME/.jabba/jabba.sh" >> ~/.zshrc
    source $HOME/.jabba/jabba.sh
else
    echo "Jabba is already installed."
    source $HOME/.jabba/jabba.sh
fi

### Check if the desired Java version is already installed and set as default
if jabba ls | grep -q "$JAVA_VERSION"; then
    echo "Java $JAVA_VERSION is already installed."
else
    echo "Installing Java version $JAVA_VERSION"
    jabba install "$JAVA_VERSION"
    jabba use "$JAVA_VERSION"
    jabba alias default "$JAVA_VERSION"
fi

## Maven

### Install Maven if not already installed
if ! command -v mvn &>/dev/null; then
    echo "Installing Maven..."
    curl -O https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
    tar xzvf apache-maven-$MAVEN_VERSION-bin.tar.gz
    sudo mv apache-maven-$MAVEN_VERSION /opt/
    sudo ln -s /opt/apache-maven-$MAVEN_VERSION/bin/mvn /usr/bin/mvn
    echo "export PATH=/opt/apache-maven-$MAVEN_VERSION/bin:\$PATH" >> ~/.zshrc
    source ~/.zshrc
    rm apache-maven-$MAVEN_VERSION-bin.tar.gz
else
    echo "Maven is already installed."
fi

echo "===================="
echo "Installed languages"
echo "===================="
python --version
go version
echo "node: $(node --version)"
rustc --version
cargo --version
java -version
mvn -version
