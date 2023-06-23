# Pipeline Variables

This document describes the general meaning of each available pipeline variable.
For more context specific meanings, refer to individual step documentation. Step
scripts should always use existing pipeline variables where one can adequately
describe the desired input.

## Configure Phase

- `CONFIGURE_GIT_REMOTE_NAME`: The name of a git remote to configure.
- `CONFIGURE_GIT_REMOTE_URL`: The url to associate with the remote
 `CONFIGURE_GIT_REMOTE_NAME`.

## Build Phase

- `BUILD_APP`: The name of the application the build artifact is associated
 with.
- `BUILD_ID`: A unique version number for the build artifact.
- `BUILD_DIR`: A path pointing to a source directory for the build.
- `BUILD_REPO`: A location (may be local or remote; step dependent) to which the
 build artifact should be published.
- `BUILD_REPO_USER`: A username to authenticate against `BUILD_REPO` with.
- `BUILD_REPO_SECRET`: A secret to authenticate against `BUILD_REPO` with.
- `BUILD_FORCE`: Disable build idempotency; perform the build step even if there
 is already an existing build for `BUILD_ID` of `BUILD_APP`.
- `BUILD_GIT_TAG`: A git tag identifying the source revision the build artifact
 is built from.

## Release Phase

- `RELEASE_CHANNEL`: Identifies the environment a build should be deployed to.
 May be something like "production", "staging", etc.
- `RELEASE_KUBE_OVERLAY`: Path to a directory containing a `kustomization.yaml`
 to be deployed. Passed directly as an argument to `kubectl apply -k`.
