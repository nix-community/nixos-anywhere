#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
files=()
find "${SCRIPT_DIR}"/* -type d | while read -r i; do
  module_name=$(basename "$i")
  markdown_file="${SCRIPT_DIR}/${module_name}.md"
  terraform-docs --config "${SCRIPT_DIR}/.terraform-docs.yml" markdown table --output-file "${markdown_file}" --output-mode inject "${module_name}"
  files+=("${markdown_file}")
done
nix fmt -- "${files[@]}"
