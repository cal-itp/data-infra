#!/bin/bash
set -e

#
# Defaults
#

test "$REPO_TAG"                || REPO_TAG=$(git describe --always --tags)
test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=local
test "$BUILD_APP"               || BUILD_APP=$(awk -F/ '{ print $1 }' <<< "$REPO_TAG")
test "$BUILD_ID"                || BUILD_ID=$(awk -F/ '{ print $2 }' <<< "$REPO_TAG")
test "$BUILD_REPO"              || BUILD_REPO=$(git config --default '' "channel.$BUILD_APP/$RELEASE_CHANNEL.build-repo")
test "$RELEASE_GIT_REMOTE_NAME" || RELEASE_GIT_REMOTE_NAME=$(git config --default '' "channel.$BUILD_APP/$RELEASE_CHANNEL.git-remote-name")
test "$RELEASE_GIT_REMOTE_URL"  || RELEASE_GIT_REMOTE_URL=$(git config --default '' "channel.$BUILD_APP/$RELEASE_CHANNEL.git-remote-url")
test "$KUBECONFIG"              || KUBECONFIG=$(git config --default '' "channel.$BUILD_APP/$RELEASE_CHANNEL.kubeconfig")

export KUBECONFIG

#
# Overrides
#

BUILD_DIR=$(git rev-parse --show-toplevel)/services/$BUILD_APP
RELEASE_KUBE_BASE=../../manifests/$BUILD_APP
RELEASE_KUBE_KUSTOMIZATION=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-release/kustomization.yaml
RELEASE_KUBE_OVERLAY=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-$RELEASE_CHANNEL
RELEASE_GIT_COMMIT_DIRTY=1
CLEANUP_GIT_CHECKOUT=$(git rev-parse --abbrev-ref HEAD)

#
# Steps
#

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

CI_STEPS=(
  validate-clean-worktree
  build-docker-image
  template-kustomize-image
  release-git-branch
  release-kube-overlay
  cleanup-git-checkout
)

for step in "${CI_STEPS[@]}"; do
  printf 'BEGIN STEP: %s\n' "$step"
  source "$CI_STEPS_DIR/$step.sh"
done
