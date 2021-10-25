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

  # Use notes from a configured remote
  if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then
    git_notes_remote_ref=refs/notes/remotes/$CONFIGURE_GIT_REMOTE_NAME/${GIT_NOTES_REF#refs/notes/}
    git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$GIT_NOTES_REF":"$git_notes_remote_ref"
    git update-ref "$GIT_NOTES_REF" "$git_notes_remote_ref"
  fi

  # Find the most recently added note which is attached to an ancestor of HEAD
  if git show-ref "$GIT_NOTES_REF"; then
    while read timestamp oid; do
      if git merge-base --is-ancestor "$oid" HEAD; then
        RELEASE_BASE=$oid
        break
      fi
    done <<-EOF
	$(while read oid; do
	printf '%s %s\n' "$(git log -1 --date=iso-strict-local --format=%cd "$GIT_NOTES_REF" -- "$oid")" "$oid"
	done <<< "$(git ls-tree --name-only "$GIT_NOTES_REF")" | sort -r)
	EOF
    printf 'No ancestors of HEAD (%s) tracked in %s; ' "$(git symbolic-ref HEAD)" "$GIT_NOTES_REF"
  else
    printf 'No releases tracked in %s; ' "$GIT_NOTES_REF"
  fi

else
  printf 'RELEASE_BASE is set to %s; skipping step\n' "$RELEASE_BASE"
fi

test "$RELEASE_BASE" || printf 'RELEASE_BASE is unset\n'
