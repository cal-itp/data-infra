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

test "$RELEASE_CHANNEL"         || RELEASE_CHANNEL=$(basename "$(git symbolic-ref HEAD)")

#
# Optional
#

test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$CONFIGURE_GIT_REMOTE_URL"  || CONFIGURE_GIT_REMOTE_URL=

export KUBECONFIG

#
# Steps
#

release_vars_root=$(git rev-parse --show-toplevel)/ci/vars/releases

printf 'BEGIN STEP: configure-git-remote\n'
source "$CI_STEPS_DIR/configure-git-remote.sh"

for env_file in "$release_vars_root"/"$RELEASE_CHANNEL"-*.env; do
  #
  # Per-app variable overrides
  #
  # CAUTION: these vars are not being loaded within a subshell, which means each
  #  app's variables are loaded into the global pipeline scope. The reason a
  #  subshell is avoided here is to allow each step to cumulatively modify the
  #  RELEASE_NOTES variable.
  while read line; do
    if [[ $line =~ ^([[:alnum:]_]+)=(.*)$ ]]; then
      declare -x "$line"
    else
      continue
    fi
  done < "$env_file"
  app_name=$(basename "$env_file" | sed 's/\.env$//')
  printf 'BEGIN STEP: release-%s-changes: %s\n' "$RELEASE_DRIVER" "$app_name"
  source "$CI_STEPS_DIR/release-$RELEASE_DRIVER-changes.sh"
done

printf 'BEGIN STEP: release-git-notes\n'
source "$CI_STEPS_DIR/release-git-notes.sh"
