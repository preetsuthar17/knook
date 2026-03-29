#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h:h}

version=${1:-}

if [[ -z "${version}" ]]; then
  echo "Usage: ${0} <version>" >&2
  exit 1
fi

scheme=${KNOOK_SCHEME:-knook}
archive_path="${repo_root}/build/${scheme}.xcarchive"
export_path="${repo_root}/build/export"
derived_data_path="${repo_root}/build/DerivedData"
project_path="${repo_root}/knook.xcodeproj"
export_options_plist="${repo_root}/packaging/macos/ExportOptions.plist"
signing_identity=${KNOOK_SIGNING_IDENTITY:-}
notary_profile=${KNOOK_NOTARY_PROFILE:-}
unsigned_preview=${KNOOK_UNSIGNED_PREVIEW:-0}
marketing_version=${KNOOK_MARKETING_VERSION:-${version}}
current_project_version=${KNOOK_CURRENT_PROJECT_VERSION:-1}

KNOOK_MARKETING_VERSION="${marketing_version}" \
KNOOK_CURRENT_PROJECT_VERSION="${current_project_version}" \
ruby "${repo_root}/packaging/macos/generate-xcodeproj.rb"

if [[ "${unsigned_preview}" == "1" ]]; then
  rm -rf "${derived_data_path}"
  xcodebuild \
    -project "${project_path}" \
    -scheme "${scheme}" \
    -configuration Release \
    -derivedDataPath "${derived_data_path}" \
    CURRENT_PROJECT_VERSION="${current_project_version}" \
    MARKETING_VERSION="${marketing_version}" \
    CODE_SIGNING_ALLOWED=NO \
    build

  app_path="${derived_data_path}/Build/Products/Release/knook.app"
  echo "Built unsigned preview app at ${app_path}"
else
  xcodebuild \
    -project "${project_path}" \
    -scheme "${scheme}" \
    -configuration Release \
    -archivePath "${archive_path}" \
    CURRENT_PROJECT_VERSION="${current_project_version}" \
    MARKETING_VERSION="${marketing_version}" \
    archive

  xcodebuild \
    -exportArchive \
    -archivePath "${archive_path}" \
    -exportPath "${export_path}" \
    -exportOptionsPlist "${export_options_plist}"

  app_path="${export_path}/knook.app"
  codesign --verify --deep --strict --verbose=2 "${app_path}"
  spctl -a -vv "${app_path}"
fi

dmg_path="$("${repo_root}/packaging/macos/create-dmg.sh" "${version}" "${app_path}")"

if [[ -n "${signing_identity}" ]]; then
  codesign --force --sign "${signing_identity}" "${dmg_path}"
fi

if [[ -n "${notary_profile}" ]]; then
  xcrun notarytool submit "${dmg_path}" --keychain-profile "${notary_profile}" --wait
  xcrun stapler staple "${dmg_path}"
  spctl -a -vv --type open "${dmg_path}"
fi

shasum -a 256 "${dmg_path}"
echo "GitHub release asset: ${dmg_path}"

if [[ "${unsigned_preview}" == "1" ]]; then
  echo "Unsigned preview build: users will need to bypass Gatekeeper on first launch."
fi
