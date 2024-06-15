#!/bin/sh
set -efu "${enable_debug:-}"
has() {
  command -v "$1" >/dev/null && echo "y" || echo "n"
}
is_nixos=$(if test -f /etc/os-release && grep -q ID=nixos /etc/os-release; then echo "y"; else echo "n"; fi)
cat <<FACTS
is_os=$(uname)
is_arch=$(uname -m)
is_kexec=$(if test -f /etc/is_kexec; then echo "y"; else echo "n"; fi)
is_nixos=$is_nixos
is_installer=$(if [ "$is_nixos" = "y" ] && grep -q VARIANT_ID=installer /etc/os-release; then echo "y"; else echo "n"; fi)
is_container=$(if [ "$(has systemd-detect-virt)" = "y" ]; then systemd-detect-virt --container; else echo "none"; fi)
has_ipv6_only=$(if [ "$(has ip)" = "n" ] || ip r g 1 >/dev/null 2>/dev/null || ! ip -6 r g :: >/dev/null 2>/dev/null; then echo "n"; else echo "y"; fi)
has_tar=$(has tar)
has_sudo=$(has sudo)
has_doas=$(has doas)
has_wget=$(has wget)
has_curl=$(has curl)
has_setsid=$(has setsid)
FACTS
