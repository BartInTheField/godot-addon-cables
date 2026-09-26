#!/bin/sh
# Installs the latest Cables release into the Godot project in the current directory (or the one given as $1).
set -eu

repo="BartInTheField/godot-addon-cables"
project="${1:-.}"

if [ ! -f "$project/project.godot" ]; then
  echo "No project.godot in $project; run this from your Godot project's root, or pass its path." >&2
  exit 1
fi
for cmd in curl unzip; do
  command -v "$cmd" >/dev/null || { echo "$cmd is required." >&2; exit 1; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

base="https://github.com/$repo/releases/latest/download"
curl -fsSL -o "$tmp/godot-addon-cables.zip" "$base/godot-addon-cables.zip"
curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"
if command -v sha256sum >/dev/null; then
  (cd "$tmp" && sha256sum -c --quiet checksums.txt)
elif command -v shasum >/dev/null; then
  (cd "$tmp" && shasum -a 256 -c --quiet checksums.txt)
fi

unzip -q "$tmp/godot-addon-cables.zip" -d "$tmp/pkg"
version=$(sed -n 's/^version="\(.*\)"/\1/p' "$tmp/pkg/addons/cables/plugin.cfg")

# Replace rather than merge, so files removed from the addon don't linger.
mkdir -p "$project/addons"
rm -rf "$project/addons/cables"
mv "$tmp/pkg/addons/cables" "$project/addons/cables"

echo "Installed Cables $version into $project/addons/cables."
echo "Enable it in Project > Project Settings > Plugins."
