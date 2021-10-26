# build-git-tag

Create an annotated tag that follows the strict naming convention
`{BUILD_APP}/{BUILD_ID}`, populate the tag message with a changelog for
`{BUILD_APP}` since the last `{BUILD_ID}` it was tagged with, and set the new
tag name as the value of `BUILD_GIT_TAG`.

## Variables

- `BUILD_APP`: The service the tag is being created for.
- `BUILD_ID`: The new version `BUILD_APP` is to be tagged with.
- `CONFIGURE_GIT_REMOTE_NAME`: If configured, the newly created tag will be
 pushed to this remote.
