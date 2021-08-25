#!/bin/bash
set -e

required_missing=()

test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$CONFIGURE_GIT_REMOTE_URL"  || CONFIGURE_GIT_REMOTE_URL=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then

  if ! git remote | grep "^$CONFIGURE_GIT_REMOTE_NAME$"; then
    git remote add "$CONFIGURE_GIT_REMOTE_NAME" "$CONFIGURE_GIT_REMOTE_URL"
  elif [[ $CONFIGURE_GIT_REMOTE_URL && $CONFIGURE_GIT_REMOTE_URL != $(git remote get-url "$CONFIGURE_GIT_REMOTE_NAME") ]]; then
    git remote set-url "$CONFIGURE_GIT_REMOTE_NAME" "$CONFIGURE_GIT_REMOTE_URL"
  fi

fi
