# configure-build-git-notes

Load build variables from a git note as prepared by the `build-git-notes` step.

## Variables

- `BUILD_GIT_TAG`: The git tag which the build note was attached to
- `GIT_NOTES_REF`: Exported for consumption by `git-notes(1)`. Defaults to
 `refs/notes/build`.
