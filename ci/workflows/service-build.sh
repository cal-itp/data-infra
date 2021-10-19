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
# Required
#

test "$BUILD_REPO"              || { printf 'BUILD_REPO: '; read BUILD_REPO; }

#
# Defaults
#

test "$BUILD_GIT_TAG"           || BUILD_GIT_TAG=$(git describe --abbrev=0)
test "$BUILD_APP"               || BUILD_APP=$(dirname "$BUILD_GIT_TAG")
test "$BUILD_ID"                || BUILD_ID=$(basename "$BUILD_GIT_TAG")
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

printf 'BEGIN STEP: validate-build-git-tag\n'
source "$CI_STEPS_DIR/validate-build-git-tag.sh"

printf 'BEGIN STEP: configure-git-remote\n'
source "$CI_STEPS_DIR/configure-git-remote.sh"

printf 'BEGIN STEP: configure-docker-login\n'
source "$CI_STEPS_DIR/configure-docker-login.sh"

printf 'BEGIN STEP: build-git-notes\n'
source "$CI_STEPS_DIR/build-git-notes.sh"

printf 'BEGIN STEP: configure-build-git-notes\n'
source "$CI_STEPS_DIR/configure-build-git-notes.sh"

printf 'BEGIN STEP: build-docker-image\n'
source "$CI_STEPS_DIR/build-docker-image.sh"
