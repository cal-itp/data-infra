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
