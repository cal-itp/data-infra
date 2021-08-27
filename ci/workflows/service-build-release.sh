#!/bin/bash
set -e

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

#
# Defaults
#

test "$BUILD_GIT_TAG"           || BUILD_GIT_TAG=$(git describe --abbrev=0)

source "$CI_STEPS_DIR/validate-build-git-tag.sh"

test "$BUILD_DIR"               || BUILD_DIR=$(git rev-parse --show-toplevel)/services/$BUILD_APP

#
# Optional
#

test "$BUILD_REPO_USER"         || BUILD_REPO_USER=
test "$BUILD_REPO_SECRET"       || BUILD_REPO_SECRET=
test "$BUILD_FORCE"             || BUILD_FORCE=

#
# Steps
#

printf 'BEGIN STEP: build-docker-image\n'
source "$CI_STEPS_DIR/build-docker-image.sh"
