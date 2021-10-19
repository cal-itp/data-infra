#!/bin/bash
set -e

test "$BUILD_REPO"        || BUILD_REPO=
test "$BUILD_REPO_USER"   || BUILD_REPO_USER=
test "$BUILD_REPO_SECRET" || BUILD_REPO_SECRET=

if [[ $BUILD_REPO =~ ([^/]+\.[^/]+)/(.*)$ ]]; then
  registry=${BASH_REMATCH[1]}

  if [[ $registry =~ .*\.ecr\.([^.]+)\.amazonaws\.com$ ]]; then
    region=${BASH_REMATCH[1]}
    BUILD_REPO_USER=AWS
    BUILD_REPO_SECRET=$(aws ecr get-login-password --region "$region")
  fi

  if [[ $registry =~ .*\.gcr\.io$ ]]; then
    gcloud auth configure-docker
  elif [[ $BUILD_REPO_USER && $BUILD_REPO_SECRET ]]; then
    docker login -u "$BUILD_REPO_USER" --password-stdin "$registry" <<< "$BUILD_REPO_SECRET"
  fi

fi
