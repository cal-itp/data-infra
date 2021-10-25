#!/bin/bash
set -e

required_missing=()

test "$RELEASE_CHANNEL" || required_missing+=('RELEASE_CHANNEL')
test "$RELEASE_BASE"    || RELEASE_BASE=$(git rev-list --max-parents=0 HEAD)

export KUBECONFIG

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

work_tree=$(git rev-parse --show-toplevel)
declare -A release_apps

# find all apps with changed manifests
while read path; do
  if [[ $path =~ ^kubernetes/apps/manifests/([^/]+)/.*$ ]]; then
    release_apps[${BASH_REMATCH[1]}]=1
  elif [[ $path =~ ^kubernetes/apps/overlays/([^/]+)-[^-/]+/.*$ ]]; then
    release_apps[${BASH_REMATCH[1]}]=1
  fi
done <<< "$(git diff-tree -r --name-only "$RELEASE_BASE" HEAD -- kubernetes/apps)"

if [[ ${#release_apps[*]} -eq 0 ]]; then
  printf 'No manifest changes found; skipping release\n'
else

  printf 'Releasing into channel: %s\n' "$RELEASE_CHANNEL"

  for app in "${!release_apps[@]}"; do
    overlay_path=$work_tree/kubernetes/apps/overlays/$app-$RELEASE_CHANNEL
    if [[ -e "$overlay_path" ]]; then
      printf 'app: %s\n' "$app"
      kubectl apply -k "$overlay_path"
    else
      printf '(skipping: %s)\n' "$app"
    fi
  done

fi

