#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                  || required_missing+=('BUILD_APP')
test "$BUILD_ID"                   || required_missing+=('BUILD_ID')
test "$BUILD_REPO"                 || required_missing+=('BUILD_REPO')
test "$CONFIGURE_GIT_REMOTE_NAME"  || CONFIGURE_GIT_REMOTE_NAME=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

git_tag_name=$BUILD_APP/$BUILD_ID
git_ref_name=refs/tags/$git_tag_name

if git show-ref "$git_ref_name"; then
  printf 'error: refusing to prepare existing tag: %s\n' "$git_tag_name"
  exit 1
fi

# Commit changes from dirty worktree
if [[ $(git status --porcelain=v1) && $RELEASE_GIT_COMMIT_DIRTY ]]; then
  git add -A
  git commit -m "rc($BUILD_APP): $BUILD_ID"
fi

# Create annotated tag
git tag -a -F - "$git_tag_name" <<EOF
BUILD_APP=$BUILD_APP
BUILD_ID=$BUILD_ID
BUILD_REPO=$BUILD_REPO
EOF

# Push release tag to remote
if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then
  git push "$CONFIGURE_GIT_REMOTE_NAME" "$git_ref_name"
fi
