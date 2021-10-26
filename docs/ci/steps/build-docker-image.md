# build-docker-image

This step performs a docker image build and optioinally pushes the built image
to a remote registry.

## Variables

- `BUILD_DIR`: Path to the docker image context directory. Passed through to
 `docker build`.
- `BUILD_REPO`: The name of the image. This is joined with `BUILD_ID` by a ":"
 character to compose a fully qualified image name as passed to
 `docker build -t`. When this value points to a remote registry, the step will
 execute a `docker push` after the image is built.
- `BUILD_ID`: The image tag. This is joined with `BUILD_REPO` by a ":" character
 to compose a fully qualified image name as passed to `docker build -t`. Do not
 specify `latest` here; the step will automatically apply the `latest` tag to the
 built image in addition to the tag specified by this value. Furthermore, doing
 so will probably cause unexpected build skips on account of the idempotency
 check.
- `BUILD_FORCE`: By default, when `BUILD_REPO` refers to a remote registry and
  that registry already contains an image with a tag matching `BUILD_ID`, the
  build step will skip work. Setting this flag will force the step to rebuild
  and repush the image regardless of its presence in the remote registry.
