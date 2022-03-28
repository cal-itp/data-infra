#!/bin/bash
set -e

required_missing=()

test "$RELEASE_NOTES"             || RELEASE_NOTES=
test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$GIT_NOTES_REF"             || GIT_NOTES_REF=refs/notes/releases/$RELEASE_CHANNEL

export GIT_NOTES_REF

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

git_notes_remote_ref=refs/notes/remotes/$CONFIGURE_GIT_REMOTE_NAME/${GIT_NOTES_REF#refs/notes/}

if [[ $RELEASE_NOTES ]]; then

  # Capture release notes
  git notes add -f --file - <<-EOF
	$RELEASE_NOTES
	EOF

  # Push release notes
  if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then

    if [[ $(git ls-remote "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF") ]]; then
      git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF":"$git_notes_remote_ref"
      git notes merge -s ours "$git_notes_remote_ref"
    fi

    git push "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF"

  fi

fi
