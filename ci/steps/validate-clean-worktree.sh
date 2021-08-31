#!/bin/bash
set -e

if [[ $(git status --porcelain=v1) ]]; then
  printf 'validation failure: git worktree is dirty\n' >&2
  exit 1
fi
