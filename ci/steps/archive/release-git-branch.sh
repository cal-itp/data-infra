#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                  || required_missing+=('BUILD_APP')
test "$BUILD_ID"                   || required_missing+=('BUILD_ID')
test "$RELEASE_CHANNEL"            || required_missing+=('RELEASE_CHANNEL')
test "$CONFIGURE_GIT_REMOTE_NAME"  || CONFIGURE_GIT_REMOTE_NAME=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

git_branch_name=releases/$BUILD_APP/$RELEASE_CHANNEL
git_ref_remote=refs/remotes/$CONFIGURE_GIT_REMOTE_NAME/$git_branch_name
git_ref_local=refs/heads/$git_branch_name
git_ref_topic=$(git symbolic-ref HEAD)

# Fork release branch from remote if it's there
if [[ $CONFIGURE_GIT_REMOTE_NAME && $(git ls-remote "$CONFIGURE_GIT_REMOTE_NAME" "$git_ref_local") ]]; then
  git fetch "$CONFIGURE_GIT_REMOTE_NAME" "$git_ref_local"
  git branch --no-track -f "$git_branch_name" "$git_ref_remote"
fi

# Otherwise, fork release branch from local HEAD
if ! [[ $(git show-ref "$git_ref_local") ]]; then
  git branch -f "$git_branch_name"
fi

# Merge topic branch into release branch
git checkout "$git_branch_name"
git merge --no-ff --no-edit -m "release($BUILD_APP/$RELEASE_CHANNEL): $BUILD_ID" "$git_ref_topic"

# Push release branch to remote
if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then
  git push "$CONFIGURE_GIT_REMOTE_NAME" "$git_ref_local":"$git_ref_local"
fi
