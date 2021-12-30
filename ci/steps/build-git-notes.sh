#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                 || required_missing+=('BUILD_APP')
test "$BUILD_ID"                  || required_missing+=('BUILD_ID')
test "$BUILD_REPO"                || required_missing+=('BUILD_REPO')
test "$BUILD_GIT_TAG"             || required_missing+=('BUILD_GIT_TAG')
test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$GIT_NOTES_REF"             || GIT_NOTES_REF=refs/notes/builds

export GIT_NOTES_REF

git_notes_remote_ref=refs/notes/remotes/$CONFIGURE_GIT_REMOTE_NAME/$(basename "$GIT_NOTES_REF")

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

# Annotate build tag with variables
if ! git notes list "$BUILD_GIT_TAG" 2>/dev/null; then
  git notes add --file - "$BUILD_GIT_TAG" <<-EOF
	BUILD_APP=$BUILD_APP
	BUILD_ID=$BUILD_ID
	BUILD_REPO=$BUILD_REPO
	EOF
fi

# Push build variable annotation
if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then

  if [[ $(git ls-remote "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF") ]]; then
    git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF":"$git_notes_remote_ref"
    git notes merge "$git_notes_remote_ref"
  fi

  git push "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF"

fi
