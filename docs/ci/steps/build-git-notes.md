# build-git-notes

Store build variables in a git note for later referencing/loading.

## Control Variables

The following variables impact the behavior of the step itself:

- `BUILD_GIT_TAG`: The git tag which the resulting note will be attached to
- `GIT_NOTES_REF`: Exported for consumption by `git-notes(1)`. Defaults to
 `refs/notes/builds`.

## Stored Variables

The following variables and their set values will be saved to the resulting git
note. These are all required.

- `BUILD_APP`
- `BUILD_ID`
- `BUILD_REPO`
