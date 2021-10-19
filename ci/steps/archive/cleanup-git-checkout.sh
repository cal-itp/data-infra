#!/bin/bash
set -e

if [[ $CLEANUP_GIT_CHECKOUT ]]; then
  git checkout "$CLEANUP_GIT_CHECKOUT"
fi
