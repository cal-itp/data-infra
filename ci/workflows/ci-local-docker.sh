#!/bin/bash
set -e

export BUILD_DIR=$(git rev-parse --show-toplevel)/ci/image
export BUILD_DEST=cal-itp/ci-local
export BUILD_ID=$(git describe --always --dirty --tags | tr '/' '_')
export CI_CONTAINER_ENVFILE=
export CI_CONTAINER_NAME=$(basename "$CI_CONTAINER_ENVFILE")-active
export CI_CONTAINER_PROJECT=$(git rev-parse --show-toplevel)

CI_STEPS_DIR=$(git rev-parse --show-toplevel)/ci/steps

source $CI_STEPS_DIR/build-docker-image.sh
source $CI_STEPS_DIR/ci-local-docker-container.sh
