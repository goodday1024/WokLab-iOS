#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v xcodegen >/dev/null || { echo 'Install XcodeGen first: brew install xcodegen'; exit 1; }
xcodegen generate
xcodebuild -project WokLab.xcodeproj -scheme WokLab -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
mkdir -p package/Payload
cp -R build/Build/Products/Release-iphoneos/WokLab.app package/Payload/
(cd package && zip -qry ../WokLab-unsigned.ipa Payload)
echo 'Created WokLab-unsigned.ipa; signing is required before normal device installation.'
