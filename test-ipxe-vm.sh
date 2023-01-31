#!/usr/bin/env bash

set -x -eu -o pipefail

VM_IF="nixos-if0"
BRIDGE_IF="nixos-br0"
VM_IMAGE="nixos-nvme.img"

extra_flags=()
if [[ -n ${OVMF-} ]]; then
  extra_flags+=("-bios" "$OVMF")
fi

for arg in "${@}"; do
  case "$arg" in
  prepare)
    sudo ip tuntap add "$VM_IF" mode tap user "$(id -un)"
    sudo ip link set dev "$VM_IF" up
    sudo ip link add "$BRIDGE_IF" type bridge
    sudo ip link set "$VM_IF" master "$BRIDGE_IF"
    truncate -s10G "$VM_IMAGE"
    ;;
  start)
    qemu-system-x86_64 -m 4G \
      -boot n \
      -smp "$(nproc)" \
      -enable-kvm \
      -cpu max \
      -netdev tap,id=mynet0,ifname="$VM_IF",script=no,downscript=no \
      -device e1000,netdev=mynet0,mac=52:55:00:d1:55:01 \
      -drive file="$VM_IMAGE",if=none,id=nvm,format=raw \
      -device nvme,serial=deadbeef,drive=nvm \
      -nographic \
      "${extra_flags[@]}"
    ;;
  destroy)
    sudo ip link del "$VM_IF" || true
    sudo ip link del "$BRIDGE_IF" || true
    rm -f "$VM_IMAGE"
    ;;
  *)
    echo "USAGE: $0 (prepare|start|destroy)"
    ;;
  esac
done
