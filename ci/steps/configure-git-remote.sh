#!/bin/bash
set -e

required_missing=()

test "$RELEASE_GIT_REMOTE_NAME"    || RELEASE_GIT_REMOTE_NAME=
test "$RELEASE_GIT_REMOTE_URL"     || RELEASE_GIT_REMOTE_URL=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

if [[ $RELEASE_GIT_REMOTE_NAME ]]; then

  if ! git remote | grep "^$RELEASE_GIT_REMOTE_NAME$"; then
    git remote add "$RELEASE_GIT_REMOTE_NAME" "$RELEASE_GIT_REMOTE_URL"
  elif [[ $RELEASE_GIT_REMOTE_URL && $RELEASE_GIT_REMOTE_URL != $(git remote get-url "$RELEASE_GIT_REMOTE_NAME") ]]; then
    git remote set-url "$RELEASE_GIT_REMOTE_NAME" "$RELEASE_GIT_REMOTE_URL"
  fi

fi
