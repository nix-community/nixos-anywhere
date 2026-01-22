#!/usr/bin/env bash
set -efu

declare file attribute nix_options special_args debug_logging target_host target_user target_port use_target_as_builder
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_options=\(.nix_options) special_args=\(.special_args) debug_logging=\(.debug_logging) target_host=\(.target_host) target_user=\(.target_user) target_port=\(.target_port) use_target_as_builder=\(.use_target_as_builder)"')"

if [ "${debug_logging}" = "true" ]; then
  set -x
fi

# Parse nix options
if [ "${nix_options}" != '{"options":{}}' ]; then
  options=$(echo "${nix_options}" | jq -r '.options | to_entries | map("--option \(.key) \(.value)") | join(" ")')
else
  options=""
fi

# Check if target can be used as remote builder
remote_builder=""
if [ "${use_target_as_builder}" = "true" ] && [ "${target_host}" != "null" ] && [ -n "${target_host}" ]; then
  ssh_target="${target_user}@${target_host}"
  ssh_opts=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)
  if [ "${target_port}" != "22" ]; then
    ssh_opts+=(-p "${target_port}")
  fi

  # Test if target has nix available
  if ssh "${ssh_opts[@]}" "${ssh_target}" "command -v nix >/dev/null 2>&1" 2>/dev/null; then
    # Get system type from target
    system_type=$(ssh "${ssh_opts[@]}" "${ssh_target}" "nix eval --raw --impure --expr 'builtins.currentSystem'" 2>/dev/null || echo "")

    if [ -n "${system_type}" ]; then
      if [ "${debug_logging}" = "true" ]; then
        echo "Using ${ssh_target} as remote builder (${system_type})" >&2
      fi

      # Build SSH URI with port if non-standard
      if [ "${target_port}" != "22" ]; then
        ssh_uri="ssh://${ssh_target}:${target_port}"
      else
        ssh_uri="ssh://${ssh_target}"
      fi

      # Configure remote builder
      # Format: URI system max-jobs speed-factor supported-features mandatory-features
      remote_builder="--builders '${ssh_uri} ${system_type} - - - - nixos-test,big-parallel,kvm'"

      # Use substitutes from cache.nixos.org on the builder
      options="${options} --option builders-use-substitutes true"
    fi
  else
    if [ "${debug_logging}" = "true" ]; then
      echo "Target ${ssh_target} does not have nix available, building locally" >&2
    fi
  fi
fi

# Execute nix build
if [[ ${special_args-} == "{}" ]]; then
  # no special arguments, proceed as normal
  if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
    # shellcheck disable=SC2086
    out=$(eval nix build --no-link --json $options $remote_builder -f "$file" "$attribute")
  else
    # shellcheck disable=SC2086
    out=$(eval nix build --no-link --json ${options} ${remote_builder} "$attribute")
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

  # Use nix flake prefetch to get the flake into the store, then use path:// URL with narHash
  prefetch_result="$(nix flake prefetch "${flake_rel}" --json)"
  store_path="$(echo "${prefetch_result}" | jq -r '.storePath')"
  nar_hash="$(echo "${prefetch_result}" | jq -r '.hash')"
  flake_url="path:${store_path}?narHash=${nar_hash}"

  # substitute variables into the template
  nix_expr="(builtins.getFlake ''${flake_url}'').${config_path}.extendModules { specialArgs = builtins.fromJSON ''${special_args}''; }"
  # inject `special_args` into nixos config's `specialArgs`

  # shellcheck disable=SC2086
  out=$(eval nix build --no-link --json ${options} ${remote_builder} --expr "${nix_expr}" "${config_attribute}")
fi
printf '%s' "$out" | jq -c '.[].outputs'
