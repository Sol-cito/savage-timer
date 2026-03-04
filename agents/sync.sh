#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

mode="${1:-pull}"

pairs=(
  "AGENTS.md|agents/scopes/root/AGENTS.md"
  "lib/AGENTS.md|agents/scopes/lib/AGENTS.md"
  "test/AGENTS.md|agents/scopes/test/AGENTS.md"
  "ios/AGENTS.md|agents/scopes/ios/AGENTS.md"
  "android/AGENTS.md|agents/scopes/android/AGENTS.md"
  "lib/services/AGENTS.md|agents/scopes/lib/services/AGENTS.md"
)

copy_file() {
  local from="$1"
  local to="$2"
  mkdir -p "$(dirname "$to")"
  cp "$from" "$to"
}

case "$mode" in
  pull)
    for pair in "${pairs[@]}"; do
      live_path="${pair%%|*}"
      mirror_path="${pair##*|}"
      copy_file "$live_path" "$mirror_path"
    done
    echo "Pulled live AGENTS.md files into agents/scopes/"
    ;;
  push)
    for pair in "${pairs[@]}"; do
      live_path="${pair%%|*}"
      mirror_path="${pair##*|}"
      copy_file "$mirror_path" "$live_path"
    done
    echo "Pushed agents/scopes AGENTS.md files into live scoped locations"
    ;;
  list)
    for pair in "${pairs[@]}"; do
      live_path="${pair%%|*}"
      mirror_path="${pair##*|}"
      echo "$live_path <=/> $mirror_path"
    done
    ;;
  *)
    echo "Usage: bash agents/sync.sh [pull|push|list]"
    exit 1
    ;;
esac
