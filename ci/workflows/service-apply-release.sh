#!/bin/bash
set -e

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

#
# Defaults
#

test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=$(basename "$(git symbolic-ref HEAD)")
test "$BUILD_GIT_TAG"           || BUILD_GIT_TAG=$(git describe --abbrev=0)

source "$CI_STEPS_DIR/validate-build-git-tag.sh"

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

printf 'BEGIN STEP: release-kube-overlay\n'
source "$CI_STEPS_DIR/release-kube-overlay.sh"
