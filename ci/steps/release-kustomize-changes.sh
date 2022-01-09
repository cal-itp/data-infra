#!/bin/bash
set -e

required_missing=()

test "$RELEASE_CHANNEL"       || required_missing+=('RELEASE_CHANNEL')
test "$RELEASE_KUSTOMIZE_DIR" || required_missing+=('RELEASE_KUSTOMIZE_DIR')

export KUBECONFIG

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

kustomize_path=$(git rev-parse --show-toplevel)/$RELEASE_KUSTOMIZE_DIR
diff_contents=$(kubectl diff -k "$kustomize_path" || true)

if [[ $diff_contents ]]; then
  printf 'release: %s\n' "$kustomize_path"
  kubectl apply -k "$kustomize_path"
  test ! "$RELEASE_NOTES" || RELEASE_NOTES+=$'\n'
  RELEASE_NOTES+=$(printf '[%s]\n\n%s\n' "$kustomize_path" "$diff_contents")
else
  printf 'skip: %s\n' "$kustomize_path"
fi
