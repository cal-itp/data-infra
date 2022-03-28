#!/bin/bash
set -e

#
# Env files
#

for env_file in "$@"; do

  if ! [[ -e "$env_file" ]]; then
    printf 'error: all cli arguments must be paths to environment files\n' >&2
    exit 1
  fi

  while read line; do
    if [[ $line =~ ^([[:alnum:]_]+)=(.*)$ ]] && ! [[ $(declare -p "${BASH_REMATCH[1]}" 2>/dev/null) ]]; then
      declare -x "$line"
    else
      continue
    fi
  done < "$env_file"

done

test "$CI_STEPS_DIR" || CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

#
# Required vars
#

test "$BUILD_APP"       || { printf 'BUILD_APP: '; read BUILD_APP; }
test "$BUILD_REPO"      || { printf 'BUILD_REPO: '; read BUILD_REPO; }
test "$RELEASE_CHANNEL" || { printf 'RELEASE_CHANNEL: '; read RELEASE_CHANNEL; }

export KUBECONFIG

#
# Defaults
#

test "$BUILD_ID"                        || BUILD_ID=$(basename "$(git describe --always --dirty)")
test "$BUILD_DIR"                       || BUILD_DIR=$(git rev-parse --show-toplevel)/services/$BUILD_APP
test "$BUILD_FORCE"                     || BUILD_FORCE=1
test "$PREPARE_KUBE_KUSTOMIZATION"      || PREPARE_KUBE_KUSTOMIZATION=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-release/kustomization.yaml
test "$PREPARE_KUBE_KUSTOMIZATION_BASE" || PREPARE_KUBE_KUSTOMIZATION_BASE=../../manifests/$BUILD_APP
test "$RELEASE_KUBE_OVERLAY"            || RELEASE_KUBE_OVERLAY=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-$RELEASE_CHANNEL

#
# Steps
#

printf 'BEGIN STEP: configure-docker-login\n'
source "$CI_STEPS_DIR/configure-docker-login.sh"

printf 'BEGIN STEP: build-docker-image\n'
source "$CI_STEPS_DIR/build-docker-image.sh"

printf 'BEGIN STEP: prepare-kustomize-image\n'
source "$CI_STEPS_DIR/prepare-kustomize-image.sh"

printf 'BEGIN STEP: release-kube-overlay\n'
source "$CI_STEPS_DIR/release-kube-overlay.sh"
