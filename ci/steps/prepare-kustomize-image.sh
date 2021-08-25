#!/bin/bash
set -e

required_missing=()

# FIXME: confusing that RELEASE_KUBE_BASE is relative while RELEASE_KUBE_KUSTOMIZATION and RELEASE_KUBE_OVERLAY are absolute
test "$BUILD_REPO"                 || required_missing+=('BUILD_REPO')
test "$BUILD_ID"                   || required_missing+=('BUILD_ID')
test "$RELEASE_KUBE_BASE"          || required_missing+=('RELEASE_KUBE_BASE')
test "$RELEASE_KUBE_KUSTOMIZATION" || required_missing+=('RELEASE_KUBE_KUSTOMIZATION')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

cat <<EOF > "$RELEASE_KUBE_KUSTOMIZATION"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- '$RELEASE_KUBE_BASE'

images:
- name: '$BUILD_REPO'
  newTag: '$BUILD_ID'
EOF
