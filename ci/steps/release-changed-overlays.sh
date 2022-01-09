#!/bin/bash
set -e

required_missing=()

test "$RELEASE_CHANNEL"        || required_missing+=('RELEASE_CHANNEL')
test "$RELEASE_MANIFESTS_ROOT" || required_missing+=('RELEASE_MANIFESTS_ROOT')
test "$RELEASE_OVERLAYS_ROOT"  || required_missing+=('RELEASE_OVERLAYS_ROOT')
test "$RELEASE_BASE"           || RELEASE_BASE='HEAD@{1}^{}'

export KUBECONFIG

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

work_tree=$(git rev-parse --show-toplevel)

for app in "$RELEASE_MANIFESTS_ROOT"/*; do
  overlay_path=$work_tree/kubernetes/apps/overlays/$app-$RELEASE_CHANNEL
  if [[ -e "$overlay_path" ]]; then
    diff_contents=$(kubectl diff -k "$overlay_path" || true)
    test "$diff_contents" || continue
    printf 'app: %s\n' "$app"
    kubectl apply -k "$overlay_path"
    test ! "$RELEASE_NOTES" || RELEASE_NOTES+=$'\n'
    RELEASE_NOTES+=$(printf '[%s]\n%s\n' "$app" "$diff_contents")
  else
    printf 'skipping app %s: no release for channel %s\n' "$app" "$RELEASE_CHANNEL"
  fi
done
