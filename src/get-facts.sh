#!/bin/sh
set -efu "${enableDebug:-}"
has() {
  command -v "$1" >/dev/null && echo "y" || echo "n"
}
isNixos=$(if test -f /etc/os-release && grep -Eq 'ID(_LIKE)?="?nixos"?' /etc/os-release; then echo "y"; else echo "n"; fi)
cat <<FACTS
isOs=$(uname)
isArch=$(uname -m)
isNixos=$isNixos
isInstaller=$(if [ "$isNixos" = "y" ] && grep -Eq 'VARIANT_ID="?installer"?' /etc/os-release; then echo "y"; else echo "n"; fi)
isContainer=$(if [ "$(has systemd-detect-virt)" = "y" ]; then systemd-detect-virt --container; else echo "none"; fi)
isRoot=$(if [ "$(id -u)" -eq 0 ]; then echo "y"; else echo "n"; fi)
hasIpv6Only=$(if [ "$(has ip)" = "n" ] || ip r g 1 >/dev/null 2>/dev/null || ! ip -6 r g :: >/dev/null 2>/dev/null; then echo "n"; else echo "y"; fi)
hasTar=$(has tar)
hasCpio=$(has cpio)
hasSudo=$(has sudo)
hasDoas=$(has doas)
hasWget=$(has wget)
hasCurl=$(has curl)
hasSetsid=$(if [ "$(has setsid)" = "y" ] && setsid --wait true 2>/dev/null; then echo "y"; else echo "n"; fi)
hasNixOSFacter=$(command -v nixos-facter >/dev/null && echo "y" || echo "n")
FACTS
