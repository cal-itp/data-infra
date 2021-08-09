#!/bin/bash
set -e

required_missing=()
want_build_push=

test "$BUILD_DIR"         || required_missing+=('BUILD_DIR')
test "$BUILD_DEST"        || required_missing+=('BUILD_DEST')
test "$BUILD_ID"          || required_missing+=('BUILD_ID')
test "$BUILD_DEST_USER"   || true
test "$BUILD_DEST_SECRET" || true

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

docker_tag=$BUILD_DEST:$BUILD_ID

# setup remote registry
if [[ $BUILD_DEST =~ ([^/]+\.[^/]+)/(.*)$ ]]; then
  want_build_push=1
  registry=${BASH_REMATCH[1]}

  if [[ $registry =~ .*\.gcr\.io$ ]]; then
    gcloud auth configure-docker
  elif [[ $BUILD_DEST_USER && $BUILD_DEST_SECRET ]]; then
    docker login -u "$BUILD_DEST_USER" --password-stdin "$registry" <<< "$BUILD_DEST_SECRET"
  fi

  if docker manifest inspect "$docker_tag"; then
    printf 'error: remote build already exists: %s\n' "$docker_tag" >&2
    exit 1
  fi

fi

docker build -t "$docker_tag" "$(git rev-parse --show-toplevel)"/"$BUILD_DIR"

if [[ $want_build_push ]]; then
  docker push "$docker_tag"
fi
