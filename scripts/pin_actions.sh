#!/usr/bin/env bash
# Remplace chaque "uses: action@tag" des workflows par "uses: action@<sha> # tag".
set -euo pipefail
cd "$(dirname "$0")/.."

grep -rhoE 'uses: [^ ]+@[^ #]+' .github/workflows | sed 's/uses: //' | sort -u |
while read -r ref; do
  action="${ref%@*}"
  tag="${ref#*@}"
  if [[ "$tag" =~ ^[0-9a-f]{40}$ ]]; then continue; fi   # deja epingle
  repo="$(echo "$action" | cut -d/ -f1-2)"
  sha="$(gh api "repos/$repo/commits/$tag" --jq .sha)"
  echo "$action@$tag -> $sha"
  sed -i "s|uses: ${action}@${tag}[[:space:]]*\$|uses: ${action}@${sha} # ${tag}|" .github/workflows/*.yml
done
