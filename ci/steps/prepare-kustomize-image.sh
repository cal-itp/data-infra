#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                       || required_missing+=('BUILD_APP')
test "$BUILD_ID"                        || required_missing+=('BUILD_ID')
test "$BUILD_REPO"                      || required_missing+=('BUILD_REPO')
test "$PREPARE_KUBE_KUSTOMIZATION"      || required_missing+=('PREPARE_KUBE_KUSTOMIZATION')
test "$PREPARE_KUBE_KUSTOMIZATION_BASE" || required_missing+=('PREPARE_KUBE_KUSTOMIZATION_BASE')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

cat <<EOF > "$PREPARE_KUBE_KUSTOMIZATION"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- '$PREPARE_KUBE_KUSTOMIZATION_BASE'

images:
- name: '$BUILD_APP'
  newName: '$BUILD_REPO'
  newTag: '$BUILD_ID'
EOF
