#!/bin/bash
set -e

if ! [[ $BUILD_GIT_TAG ]]; then
  printf 'validation failure: BUILD_GIT_TAG not defined\n' >&2
  exit 1
fi

tag_type=$(git cat-file -t "$BUILD_GIT_TAG")

if [[ $tag_type != tag ]]; then
  printf 'validation failure: expected BUILD_GIT_TAG (%s) to be an annotated tag; got type: %s\n' >&2 "$BUILD_GIT_TAG" "$tag_type"
  exit 1
fi

required_missing=()

eval "$(git tag -l --format='%(contents)' "$BUILD_GIT_TAG" | grep '^BUILD_.*=')"
test "$BUILD_APP"  || required_missing+=('BUILD_APP')
test "$BUILD_ID"   || required_missing+=('BUILD_ID')
test "$BUILD_REPO" || required_missing+=('BUILD_REPO')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'validation failure: git tag %s description missing required variables: %s\n' "$BUILD_GIT_TAG" "${required_missing[*]}" >&2
  exit 1
fi
