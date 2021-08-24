#!/bin/bash
set -e

required_missing=()
want_build_push=

test "$BUILD_DIR"         || required_missing+=('BUILD_DIR')
test "$BUILD_REPO"        || required_missing+=('BUILD_REPO')
test "$BUILD_ID"          || required_missing+=('BUILD_ID')
test "$BUILD_REPO_USER"   || BUILD_REPO_USER=
test "$BUILD_REPO_SECRET" || BUILD_REPO_SECRET=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

docker_tag=$BUILD_REPO:$BUILD_ID
docker_tag_latest=$BUILD_REPO:latest

# setup remote registry
if [[ $BUILD_REPO =~ ([^/]+\.[^/]+)/(.*)$ ]]; then
  want_build_push=1
  registry=${BASH_REMATCH[1]}

  if [[ $registry =~ .*\.gcr\.io$ ]]; then
    gcloud auth configure-docker
  elif [[ $BUILD_REPO_USER && $BUILD_REPO_SECRET ]]; then
    docker login -u "$BUILD_REPO_USER" --password-stdin "$registry" <<< "$BUILD_REPO_SECRET"
  fi

  if docker manifest inspect "$docker_tag"; then
    printf 'error: remote build already exists: %s\n' "$docker_tag" >&2
    exit 1
  fi

fi

docker build -t "$docker_tag" -t "$docker_tag_latest" "$BUILD_DIR"

if [[ $want_build_push ]]; then
  docker push "$docker_tag"
  docker push "$docker_tag_latest"
fi
