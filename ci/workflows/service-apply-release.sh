#!/bin/bash
set -e

#
# Defaults
#

test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=$(basename "$(git symbolic-ref HEAD)")
test "$BUILD_GIT_TAG"           || BUILD_GIT_TAG=$(git describe --abbrev=0)
test "$BUILD_APP"               || BUILD_APP=$(git tag -l --format='%(contents)' "$BUILD_GIT_TAG" | grep '^BUILD_APP=' | cut -d= -f2-)
test "$BUILD_ID"                || BUILD_ID=$(git tag -l --format='%(contents)' "$BUILD_GIT_TAG" | grep '^BUILD_ID=' | cut -d= -f2-)
test "$BUILD_REPO"              || BUILD_REPO=$(git tag -l --format='%(contents)' "$BUILD_GIT_TAG" | grep '^BUILD_REPO=' | cut -d= -f2-)
test "$BUILD_DIR"               || BUILD_DIR=$(git rev-parse --show-toplevel)/services/$BUILD_APP
test "$RELEASE_KUBE_OVERLAY"    || RELEASE_KUBE_OVERLAY=$(git rev-parse --show-toplevel)/kubernetes/apps/overlays/$BUILD_APP-$RELEASE_CHANNEL

#
# Optional
#

test "$BUILD_REPO_USER"         || BUILD_REPO_USER=
test "$BUILD_REPO_SECRET"       || BUILD_REPO_SECRET=
test "$BUILD_FORCE"             || BUILD_FORCE=

export KUBECONFIG

#
# Steps
#

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

printf 'BEGIN STEP: validate-clean-worktree\n'
source "$CI_STEPS_DIR/validate-clean-worktree.sh"

printf 'BEGIN STEP: build-docker-image\n'
source "$CI_STEPS_DIR/build-docker-image.sh"

printf 'BEGIN STEP: release-kube-overlay\n'
source "$CI_STEPS_DIR/release-kube-overlay.sh"
