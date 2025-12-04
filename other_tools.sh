#!/usr/bin/env zsh
set -euo pipefail

# Exit if not Linux
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script supports only Linux. Detected: $(uname -s). Aborting."
  exit 1
fi

install_k6() {
  if command -v k6 >/dev/null 2>&1; then
    echo "k6 is already installed: $(k6 version)"
    return 0
  fi

  echo "Installing k6..."

  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://dl.k6.io/key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg

  echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
    https://dl.k6.io/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/k6.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y k6

  echo "k6 installed: $(k6 version)"
}

main() {
  install_k6

  echo "===================="
  echo "Installed tool versions"
  echo "===================="
  k6 version || echo "k6: not installed"
}

main
