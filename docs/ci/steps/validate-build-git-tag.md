# validate-build-git-tag

Force exit with an error if `BUILD_GIT_TAG` is not defined or if it is not an
annotated tag of which the name adheres to the strict form
`{BUILD_APP}/{BUILD_ID}`.

## Variables

- `BUILD_GIT_TAG`: The name of the tag to be validated.
