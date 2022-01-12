#!/bin/bash
set -e

required_missing=()

test "$RELEASE_CHANNEL"           || required_missing+=('RELEASE_CHANNEL')
test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$GIT_NOTES_REF"             || GIT_NOTES_REF=refs/notes/releases/$RELEASE_CHANNEL

export GIT_NOTES_REF

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

if ! [[ $RELEASE_BASE ]]; then

  parents=($(git show -s --pretty=format:%p HEAD))

  if [[ ${#parents[*]} -lt 2 ]]; then
    printf 'HEAD (%s) is not a merge commit; ' "$(git rev-parse --short $(git rev-list -1 HEAD))"
  else
    RELEASE_BASE=${parents[0]}
  fi

else
  printf 'RELEASE_BASE is set to %s; skipping step\n' "$RELEASE_BASE"
fi

test "$RELEASE_BASE" || printf 'RELEASE_BASE is unset\n'
