# Git Flow for Services

This document describes how to utilize git flows powered by the CI framework
embedded in this repository in order to automate the build of docker images
defined in the `services` tree and automate the deployment of applications
defined in the `kubernetes/apps` tree.

## 1.0 Build

This flow is powered by:
[`.github/workflows/service-build.yml`](../../.github/workflows/service-build.yml)

### 1.1 quick start

```bash
# this is a path under services/$app_name
app_name=gtfs-rt-archive
# this would normally be something like 1.0, 1.1, etc
app_version=$(whoami).$(date +%Y-%M-%d@%H%M)
# choose your appropriate remote name if different
git_remote=origin

# an annotated tag is a requirement; lightweight tags are not accepted
# see below for details on using the more convenient build-git-tag intaerface
git tag -a "${app_name}/${app_version}"

# push the annotated tag; this triggers the image build which is then pushed to
# the gcr repository
git push "$git_remote" "${app_name}/${app_version}"
```

### 1.2 details

The tag name MUST adhere to the `${app_name}/${app_version}` convention. This
name will be parsed in order to help name the resulting docker image.

The `$app_name` in the git tag must match a path at `services/$app_name` which
contains a Dockerfile. This name also corresponds to the repository portion of
the image name name which is pushed to the GCR registry.

The `$app_version` in the git tag will be used as the tag portion of the docker
image name which is pushed to the registry.

Consequently, the resulting image build is pushed to
`{gcr_registry}/{app_name}:{app_version}`.

It is recommended to use the `build-git-tag` step to create the tag, like:

```bash
export BUILD_APP=$app_name
export BUILD_ID=$app_version
export CONFIGURE_GIT_REMOTE_NAME=$git_remote
./ci/steps/build-git-tag.sh
```

Using this build step to create a service tag offers a few conveniences:

- Inputs are validated, ensuring the git tag is created with a properly formed
 name.
- The tag message is auto-generated, consisting of a changelog of all changes to
 `services/$app_name` since the previous release of the service.
- The tag is auto-pushed to the git remote after creation, triggering the build
 process.

## 2.0 Deploy

This flow is powered by:
[`.github/workflows/service-release.yml`](../../.github/workflows/service-release.yml)

### 2.1 quick start

```bash
# this is a path under kubernetes/apps/manifests/$app_name
app_name=gtfs-rt-archive
# this should be the $app_version part of the most recent tag for $app_name
app_version=$(basename "$(git describe --abbrev=0)")
# choose your appropriate remote name if different
git_remote=origin

# bump the newTag version to match the newly pushed $app_version
$EDITOR kubernetes/apps/overlays/$app_name-release/kustomization.yaml

# commit the change
git commit -am "ops($app_name): release $app_version"

# after the push, open a PR into the releases/preprod branch.
# the release will be auto-deployed after merge
git push $git_remote $(git symbolic-ref HEAD)
# after it looks good in preprod, open a PR from releases/preprod into the
# releases/prod branch. The release will be auto-deployed after merge.
```

### 2.2 details

The automated deploy process essentially consists of modifying any yaml files
associated with a kubernetes deployment as desired, pushing those files to the
GitHub repository, and merging those changes into a release branch. Each release
branch is tied to a specific "release channel", which is simply a less ambiguous
term used to describe an "environment" (e.g., "production", "staging", etc).
There are currently two release branches:

1. `releases/preprod`
2. `releases/prod`

The basename of the branch (i.e., the name after the last "/" character) is used
to determine the name of the release channel being deployed into.

Currently, only kustomize based manifests
(`kubernetes/apps/{manifests,overlays}`) are automatically deployed into
release channels. When an update to a kustomize manifest is detected after a
merge into a release branch, the ci pipeline will execute the command:

```bash
kubectl apply -k kubernetes/apps/manifests/$app_name-$release_channel
```
