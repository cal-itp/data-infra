#!/bin/bash
set -e

required_missing=()

test "$CONFIGURE_GIT_REMOTE_NAME" || CONFIGURE_GIT_REMOTE_NAME=
test "$GIT_NOTES_REF"             || GIT_NOTES_REF=refs/notes/releases/$RELEASE_CHANNEL

export GIT_NOTES_REF

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

git_notes_remote_ref=refs/notes/remotes/$CONFIGURE_GIT_REMOTE_NAME/${GIT_NOTES_REF#refs/notes/}

if [[ ${#release_apps[*]} -gt 0 ]]; then

  # Record deployed apps
  git notes add -f --file - <<-EOF
	$(for app in "${!release_apps[@]}"; do printf 'Released-App-Name: %s\n' "$app"; done )
	EOF

  # Push deployment notes
  if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then

    if [[ $(git ls-remote "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF") ]]; then
      git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF":"$git_notes_remote_ref"
      git notes merge -s ours "$git_notes_remote_ref"
    fi

    git push "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF"

  fi

fi
