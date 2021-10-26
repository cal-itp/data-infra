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

test "$BUILD_APP"  || { printf 'BUILD_APP: '; read BUILD_APP; }
test "$BUILD_ID"   || { printf 'BUILD_ID: '; read BUILD_ID; }
test "$BUILD_REPO" || { printf 'BUILD_REPO: '; read BUILD_REPO; }

export KUBECONFIG

#
# Defaults
#

test "$PREPARE_GIT_COMMIT_MSG"          || PREPARE_GIT_COMMIT_MSG="rc($BUILD_APP): $BUILD_ID"
test "$PREPARE_KUBE_KUSTOMIZATION"      || PREPARE_KUBE_KUSTOMIZATION=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-release/kustomization.yaml
test "$PREPARE_KUBE_KUSTOMIZATION_BASE" || PREPARE_KUBE_KUSTOMIZATION_BASE=../../manifests/$BUILD_APP

#
# Steps
#

printf 'BEGIN STEP: validate-clean-worktree\n'
source "$CI_STEPS_DIR/validate-clean-worktree.sh"

printf 'BEGIN STEP: configure-git-remote\n'
source "$CI_STEPS_DIR/configure-git-remote.sh"

printf 'BEGIN STEP: prepare-kustomize-image\n'
source "$CI_STEPS_DIR/prepare-kustomize-image.sh"

printf 'BEGIN STEP: prepare-git-commit-dirty\n'
source "$CI_STEPS_DIR/prepare-git-commit-dirty.sh"

printf 'BEGIN STEP: build-git-tag\n'
source "$CI_STEPS_DIR/build-git-tag.sh"
