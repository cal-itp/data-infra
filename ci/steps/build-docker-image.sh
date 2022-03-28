#!/bin/bash
set -e

required_missing=()
want_build_push=
skip_build=

test "$BUILD_DIR"         || required_missing+=('BUILD_DIR')
test "$BUILD_REPO"        || required_missing+=('BUILD_REPO')
test "$BUILD_ID"          || required_missing+=('BUILD_ID')
test "$BUILD_REPO_USER"   || BUILD_REPO_USER=
test "$BUILD_REPO_SECRET" || BUILD_REPO_SECRET=
test "$BUILD_FORCE"       || BUILD_FORCE=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

docker_tag=$BUILD_REPO:$BUILD_ID
docker_tag_latest=${BUILD_REPO}:latest

# skip build for existing images
if [[ $BUILD_REPO =~ ([^/]+\.[^/]+)/(.*)$ ]]; then
  want_build_push=1

  if docker manifest inspect "$docker_tag" && ! [[ $BUILD_FORCE ]]; then
    printf 'info: skipping build %s: already exists in registry\n' "$docker_tag" >&2
    skip_build=1
  fi

fi

if ! [[ $skip_build ]]; then

  docker build -t "$docker_tag" -t "$docker_tag_latest" "$BUILD_DIR"
  if [[ $want_build_push ]]; then
    docker push "$docker_tag"
    docker push "$docker_tag_latest"
  fi

fi
