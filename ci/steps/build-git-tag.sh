#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                  || required_missing+=('BUILD_APP')
test "$BUILD_ID"                   || required_missing+=('BUILD_ID')
test "$CONFIGURE_GIT_REMOTE_NAME"  || CONFIGURE_GIT_REMOTE_NAME=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

BUILD_GIT_TAG=$BUILD_APP/$BUILD_ID
git_ref_name=refs/tags/$BUILD_GIT_TAG

if git show-ref "$git_ref_name"; then
  printf 'error: refusing to prepare existing tag: %s\n' "$BUILD_GIT_TAG"
  exit 1
fi

prev_tag=$(git for-each-ref --sort=-taggerdate --format '%(refname)' --count=1 refs/tags/$BUILD_APP)

if [[ $prev_tag ]]; then
  # Generate changelog based on previous release
  tag_msg=$(git shortlog "$prev_tag.." -- "$(git rev-parse --show-toplevel)/services/$BUILD_APP")
  test "$tag_msg" || tag_msg="No changes since ${prev_tag#refs/tags/}"
else
  # First release; no changelog to generate
  tag_msg="Initial release"
fi

# Create annotated tag
git tag -a -m "$tag_msg" "$BUILD_GIT_TAG"

# Push release tag to remote
if [[ $CONFIGURE_GIT_REMOTE_NAME ]]; then
  git push "$CONFIGURE_GIT_REMOTE_NAME" "$git_ref_name"
fi
