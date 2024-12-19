#!/usr/bin/env bash
set -efu

declare file attribute nix_argstrs nix_options special_args
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_argstrs=\(.nix_argstrs) nix_options=\(.nix_options) special_args=\(.special_args)"')"
if [ "${nix_argstrs}" != '{"argstrs":{}}' ]; then
  argstrs=$(echo "${nix_argstrs}" | jq -r '.argstrs | to_entries | map("--argstr \(.key) \(.value)") | join(" ")')
else
  argstrs=""
fi
if [ "${nix_options}" != '{"options":{}}' ]; then
  options=$(echo "${nix_options}" | jq -r '.options | to_entries | map("--option \(.key) \(.value)") | join(" ")')
else
  options=""
fi
if [[ ${special_args-} == "{}" ]]; then
  # no special arguments, proceed as normal
  if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
    # shellcheck disable=SC2086
    out=$(nix build --no-link --json $argstrs $options -f "$file" "$attribute")
  else
    # shellcheck disable=SC2086
    out=$(nix build --no-link --json ${options} "$attribute")
  fi
else
  if [[ ${file-} != 'null' ]]; then
    echo "special_args are currently only supported when using flakes!" >&2
    exit 1
  fi
  # pass the args in a pure fashion by extending the original config
  rest="$(echo "${attribute}" | cut -d "#" -f 2)"
  # e.g. config_path=nixosConfigurations.aarch64-linux.myconfig
  config_path="${rest%.config.*}"
  # e.g. config_attribute=config.system.build.toplevel
  config_attribute="config.${rest#*.config.}"

  # grab flake nar from error message
  flake_rel="$(echo "${attribute}" | cut -d "#" -f 1)"
  # e.g. flake_rel="."
  flake_dir="$(readlink -f "${flake_rel}")"
  flake_nar="$(nix flake prefetch "${flake_dir}" --json | jq -r '.hash')"
  # substitute variables into the template
  nix_expr="(builtins.getFlake ''file://${flake_dir}/flake.nix?narHash=${flake_nar}'').${config_path}.extendModules { specialArgs = builtins.fromJSON ''${special_args}''; }"
  # inject `special_args` into nixos config's `specialArgs`
  # shellcheck disable=SC2086
  out=$(nix build --no-link --json ${options} --expr "${nix_expr}" "${config_attribute}")
fi
printf '%s' "$out" | jq -c '.[].outputs'
