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
