#!/bin/zsh

export PYTHON_VERSION="3.11.4"
export NODE_VERSION="20"
export JAVA_VERSION="openjdk@1.17.0"
export GO_VERSION="go1.22.2"
export RUST_VERSION="1.79.0"
export MAVEN_VERSION="3.8.8"

# Check the operating system
OS=$(uname -s)

# Install pyenv if not already installed
install_pyenv() {
    if ! command -v pyenv &>/dev/null; then
        if [[ "$OS" == "Darwin" ]]; then
            echo "Installing pyenv using Homebrew..."
            brew install pyenv
        else
            echo "Installing pyenv..."
            curl https://pyenv.run | bash
        fi

        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
        echo 'eval "$(pyenv init -)"' >> ~/.zshrc
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
        source ~/.zshrc  # Reload the shell configuration
    else
        echo "pyenv is already installed."
    fi
}

# Install and set Python version
install_python() {
    if ! pyenv versions --bare | grep -q "^$PYTHON_VERSION\$"; then
        echo "Installing Python $PYTHON_VERSION"
        pyenv install $PYTHON_VERSION
    else
        echo "Python $PYTHON_VERSION is already installed."
    fi

    pyenv global $PYTHON_VERSION
    python -m ensurepip --upgrade
}

# Install GVM and Go
install_gvm_and_go() {
    if [ ! -d "$HOME/.gvm" ]; then
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

        source $HOME/.gvm/scripts/gvm || {
            echo "Failed to source GVM scripts."
            exit 1
        }

        # Install and use a Go version for bootstrap
        gvm install go1.20.6 -B
        gvm use go1.20.6
        export GOROOT_BOOTSTRAP=$GOROOT

        # Install target version of Go
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
}

# Install Node.js using NVM
install_nvm_and_node() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    if ! command -v nvm &>/dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        source $NVM_DIR/nvm.sh  # Ensure the nvm command is available
    else
        echo "NVM is already installed."
        source $NVM_DIR/nvm.sh
    fi

    # Check if the desired Node.js version is already installed
    if nvm list | grep -q "v$NODE_VERSION"; then
        echo "Node.js $NODE_VERSION is already installed."
    else
        nvm install $NODE_VERSION
        echo "Node.js $NODE_VERSION installed successfully."
    fi
}

# Install Rust using rustup
install_rust() {
    if ! command -v rustc &>/dev/null; then
        echo "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

        echo "export PATH=\"$HOME/.cargo/bin:\$PATH\"" >> ~/.zshrc
        source ~/.zshrc
    else
        echo "Rust is already installed."
    fi

    # Check if the desired Rust version is already installed and set as default
    if rustc --version | grep -q "$RUST_VERSION"; then
        echo "Rust $RUST_VERSION is already installed and set as default."
    else
        echo "Installing Rust version $RUST_VERSION"
        rustup toolchain install $RUST_VERSION
        rustup default $RUST_VERSION
    fi
}

# Install Java using Jabba
install_java() {
    echo "Installing Jabba..."
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash

    echo "source $HOME/.jabba/jabba.sh" >> ~/.zshrc
    source $HOME/.jabba/jabba.sh

    # Check if the desired Java version is already installed and set as default
    if jabba ls | grep -q "$JAVA_VERSION"; then
        echo "Java $JAVA_VERSION is already installed."
    else
        echo "Installing Java version $JAVA_VERSION"
        jabba install "$JAVA_VERSION"
        jabba use "$JAVA_VERSION"
        jabba alias default "$JAVA_VERSION"
    fi
}

# Main installation function
main() {
    install_pyenv
    install_python
    install_gvm_and_go
    install_nvm_and_node
    install_rust
    install_java
}

main

echo "===================="
echo "Installed languages"
echo "===================="
python --version
go version
echo "node: $(node --version)"
rustc --version
cargo --version
java -version
