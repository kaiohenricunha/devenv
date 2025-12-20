#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[virtualization] Linux only. Skipping."
  exit 0
fi

log() {
  printf "[virtualization] %s\n" "$*"
}

USER_NAME="${SUDO_USER:-$USER}"

log "Installing KVM/QEMU + libvirt + virt-manager..."

sudo apt-get update

# Required packages
PKGS=(
  qemu-kvm
  qemu-utils
  libvirt-daemon-system
  libvirt-clients
  virt-manager
  ovmf
  swtpm
  bridge-utils
  dnsmasq-base
  iptables
)

sudo apt-get install -y "${PKGS[@]}"

# Optional package(s)
if apt-cache show cpu-checker >/dev/null 2>&1; then
  sudo apt-get install -y cpu-checker
else
  log "Optional package not found in apt cache: cpu-checker (skipping)"
fi

log "Enabling libvirtd..."
sudo systemctl enable --now libvirtd

log "Adding user '$USER_NAME' to groups: libvirt, kvm"
sudo usermod -aG libvirt,kvm "$USER_NAME"
log "IMPORTANT: log out and log back in (or reboot) for group membership to take effect."

# Verify KVM device
if [[ -e /dev/kvm ]]; then
  log "/dev/kvm exists."
  if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    log "/dev/kvm is readable/writable for the current session."
  else
    log "NOTE: /dev/kvm is not accessible in the current session (expected until you re-login)."
  fi
else
  log "WARNING: /dev/kvm not found. BIOS/UEFI virtualization may be disabled or unsupported."
fi

# Quick capability check if cpu-checker is installed
if command -v kvm-ok >/dev/null 2>&1; then
  log "Running kvm-ok (non-fatal)..."
  kvm-ok || true
else
  log "kvm-ok not available (cpu-checker not installed)."
fi

# Libvirtd status summary
log "libvirtd status:"
systemctl is-enabled libvirtd 2>/dev/null || true
systemctl is-active libvirtd 2>/dev/null || true
systemctl --no-pager --full status libvirtd 2>/dev/null | sed -n '1,12p' || true

# Ensure libvirt default network is enabled
if command -v virsh >/dev/null 2>&1; then
  log "Checking libvirt networks..."

  if sudo virsh net-list --all >/dev/null 2>&1; then
    if sudo virsh net-list --all | awk '{print $1}' | grep -qx "default"; then
      state="$(sudo virsh net-info default 2>/dev/null | awk -F': *' '/Active:/ {print $2}')"

      if [[ "${state:-no}" != "yes" ]]; then
        log "Starting default libvirt network (non-fatal)..."
        sudo virsh net-start default || true
      fi

      log "Enabling autostart for default libvirt network (non-fatal)..."
      sudo virsh net-autostart default || true
    else
      log "WARNING: libvirt 'default' network not found. Not creating custom XML (out of scope)."
      log "Next steps: open virt-manager and create/enable a network, or check: sudo virsh net-list --all"
    fi
  else
    log "WARNING: virsh exists but libvirt is not responding. Check: systemctl status libvirtd"
  fi
else
  log "virsh not found; skipping libvirt network checks."
fi

log "Done. Launch: virt-manager"
