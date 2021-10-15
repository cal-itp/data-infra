#!/bin/bash
set -e

required_missing=()

test "$PREPARE_GIT_COMMIT_MSG" || required_missing+=('PREPARE_GIT_COMMIT_MSG')

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

# Commit changes from dirty worktree
if [[ $(git status --porcelain=v1) ]]; then
  git add -A
  git commit -m "$PREPARE_GIT_COMMIT_MSG"
fi
