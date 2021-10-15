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

test "$BUILD_APP"               || { printf 'BUILD_APP: '; read BUILD_APP; }

#
# Defaults
#

test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=$(basename "$(git symbolic-ref HEAD)")
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
