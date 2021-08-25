#!/bin/bash
set -e

#
# Defaults
#

test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=$(git config --default 'local' "branch.$(git rev-parse --abbrev-ref HEAD).release-channel")
test "$REPO_TAG"                || REPO_TAG=$(git describe --always --tags)
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
RELEASE_KUBE_OVERLAY=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-$RELEASE_CHANNEL
CLEANUP_GIT_CHECKOUT=$(git rev-parse --abbrev-ref HEAD)

#
# Steps
#

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

printf 'BEGIN STEP: validate-clean-worktree\n'
source "$CI_STEPS_DIR/validate-clean-worktree.sh"

printf 'BEGIN STEP: build-docker-image\n'
source "$CI_STEPS_DIR/build-docker-image.sh"

printf 'BEGIN STEP: release-git-branch\n'
source "$CI_STEPS_DIR/release-git-branch.sh"

printf 'BEGIN STEP: release-kube-overlay\n'
source "$CI_STEPS_DIR/release-kube-overlay.sh"

printf 'BEGIN STEP: cleanup-git-checkout\n'
source "$CI_STEPS_DIR/cleanup-git-checkout.sh"
