#!/bin/bash
set -e

required_missing=()

test "$RELEASE_CHANNEL"        || required_missing+=('RELEASE_CHANNEL')
test "$RELEASE_MANIFESTS_ROOT" || required_missing+=('RELEASE_MANIFESTS_ROOT')
test "$RELEASE_OVERLAYS_ROOT"  || required_missing+=('RELEASE_OVERLAYS_ROOT')

export KUBECONFIG

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

work_tree=$(git rev-parse --show-toplevel)

for app_base in "$RELEASE_MANIFESTS_ROOT"/*; do
  app_name=$(basename "$app_base")
  overlay_path=$work_tree/kubernetes/apps/overlays/$app_name-$RELEASE_CHANNEL
  if [[ -e "$overlay_path" ]]; then
    diff_contents=$(kubectl diff -k "$overlay_path" || true)
    test "$diff_contents" || continue
    printf 'app: %s\n' "$app_name"
    kubectl apply -k "$overlay_path"
    test ! "$RELEASE_NOTES" || RELEASE_NOTES+=$'\n'
    RELEASE_NOTES+=$(printf '[%s]\n\n%s\n' "$app_name" "$diff_contents")
  else
    printf 'skipping app %s: no release for channel %s\n' "$app_name" "$RELEASE_CHANNEL"
  fi
done
