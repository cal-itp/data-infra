#!/bin/bash
set -e

#
# CLI Overrides
#

for arg in "$@"; do
  eval "${arg%%=*}=\"${arg#*=}\""
done

#
# Required vars
#

test "$BUILD_APP"  || { printf 'BUILD_APP: '; read BUILD_APP; }
test "$BUILD_ID"   || { printf 'BUILD_ID: '; read BUILD_ID; }
test "$BUILD_REPO" || { printf 'BUILD_REPO: '; read BUILD_REPO; }

export KUBECONFIG

#
# Overrides
#

PREPARE_GIT_COMMIT_MSG="rc($BUILD_APP): $BUILD_ID"
RELEASE_KUBE_BASE=../../manifests/$BUILD_APP
RELEASE_KUBE_KUSTOMIZATION=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-release/kustomization.yaml
RELEASE_GIT_COMMIT_DIRTY=1

#
# Steps
#

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

CI_STEPS=(
  validate-clean-worktree
  configure-git-remote
  template-kustomize-image
  prepare-git-commit-dirty
  release-git-tag
)

for step in "${CI_STEPS[@]}"; do
  printf 'BEGIN STEP: %s\n' "$step"
  source "$CI_STEPS_DIR/$step.sh"
done
