#!/bin/bash
set -e

required_missing=()

test "$RELEASE_KUBE_OVERLAY" || required_missing+=('RELEASE_KUBE_OVERLAY')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

kubectl apply -k "$RELEASE_KUBE_OVERLAY"
