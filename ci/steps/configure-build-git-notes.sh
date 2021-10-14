#!/bin/bash
set -e

if ! [[ $BUILD_GIT_TAG ]]; then
  printf 'validation failure: BUILD_GIT_TAG not defined\n' >&2
  exit 1
fi

test "$GIT_NOTES_REF" || GIT_NOTES_REF=refs/notes/builds

export GIT_NOTES_REF

# Use notes from a configured remote
if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then
  git_notes_remote_ref=refs/notes/remotes/$CONFIGURE_GIT_REMOTE_NAME/$(basename "$GIT_NOTES_REF")
  git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF":"$git_notes_remote_ref"
  git update-ref "$GIT_NOTES_REF" "$git_notes_remote_ref"
fi

required_missing=()

eval "$(git notes show "$BUILD_GIT_TAG" | grep '^BUILD_.*=')"
test "$BUILD_APP"  || required_missing+=('BUILD_APP')
test "$BUILD_ID"   || required_missing+=('BUILD_ID')
test "$BUILD_REPO" || required_missing+=('BUILD_REPO')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'validation failure: git tag %s notes (ref: %s) missing required variables: %s\n' "$BUILD_GIT_TAG" "$GIT_NOTES_REF" "${required_missing[*]}" >&2
  exit 1
fi
