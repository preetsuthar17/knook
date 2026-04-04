#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h:h}

version=${1:-${KNOOK_VERSION:-}}
app_path=${2:-${KNOOK_APP_PATH:-"${repo_root}/build/export/knook.app"}}

if [[ -z "${version}" ]]; then
  echo "Usage: ${0} <version> [app-path]" >&2
  exit 1
fi

if [[ ! -d "${app_path}" ]]; then
  echo "Missing app bundle at ${app_path}" >&2
  exit 1
fi

output_dir="${repo_root}/build"
staging_dir="${output_dir}/dmg"
output_dmg="${output_dir}/knook-${version}.dmg"

rm -rf "${staging_dir}"
mkdir -p "${staging_dir}"
cp -R "${app_path}" "${staging_dir}/knook.app"
ln -s /Applications "${staging_dir}/Applications"
rm -f "${output_dmg}"

hdiutil create \
  -volname "knook" \
  -srcfolder "${staging_dir}" \
  -ov \
  -format UDZO \
  "${output_dmg}" >&2

echo "${output_dmg}"
