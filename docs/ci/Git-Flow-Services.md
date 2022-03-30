# Git Flow for Services

This document describes how to utilize git flows powered by the CI framework
embedded in this repository in order to automate the build of docker images
defined in the `services` tree and automate the deployment of applications
defined in the `kubernetes/apps` tree.

## 1.0 Build

This flow is powered by:
[`.github/workflows/service-build.yml`](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/service-build.yml)

### 1.1 quick start

```bash
# this is a path under services/$app_name
app_name=gtfs-rt-archive
# this would normally be something like 1.0, 1.1, etc
app_version=$(whoami).$(date +%Y-%M-%d@%H%M)
# choose your appropriate remote name if different
git_remote=origin

# an annotated tag is a requirement; lightweight tags are not accepted
# see below for details on using the more convenient build-git-tag interface
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

## 2.0.0 Deploy

This flow is powered by:

- [`.github/workflows/service-release-candidate.yml`](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/service-release-candidate.yml)
- [`.github/workflows/service-release-channel.yml`](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/service-release-channel.yml)

### 2.1.0 quick start

#### 2.1.1 deploy your topic branch to preprod

```bash
# this can be determined from a release config under ci/vars/releases
app_name=gtfs-rt-archive
# choose your appropriate remote name if different
git_remote=origin
topic_branch=$(git branch --show-current)
# load the helm or kustomize specific parameters
source ci/vars/releases/prod-$app_name.env

if   [[ $RELEASE_DRIVER == 'kustomize' ]]; then
  # bump the newTag version to match the newly pushed app version
  $EDITOR kubernetes/apps/overlays/$app_name-release/kustomization.yaml
elif [[ $RELEASE_DRIVER == 'helm'      ]]; then
  # update the tag part of the image parameter; how to do this may vary from app to app
  # the RELEASE_HELM_VALUES parameter in the release config points to the values file which should be changed
  $EDITOR $RELEASE_HELM_VALUES
fi

# commit the change
git commit -am "ops($app_name): release new version"

# trigger a release candidate build
git push $git_remote

#
# wait for the "Build release candidate" action to complete in GitHub
#

# fetch the release candidate
git fetch $git_remote candidates/$topic_branch

# deploy to preprod
git push -f $git_remote $git_remote/candidates/$topic_branch:releases/preprod

# after it looks good in preprod, merge your changes into main.
```

#### 2.1.2 Deploy your changes to prod

In GitHub:

1. Go through the typical PR process to merge your topic branch into `main`
2. Open a PR from `candidates/main` into `releases/prod`
3. Receive an approval
4. Merge the change

### 2.2.0 details

The automated deploy process essentially consists of:

1. Modifying yaml files associated with an app as desired
2. Push those files to the GitHub repository
3. Wait for a release candidate to build
4. Merge or push the release candidate into a release branch

#### 2.2.1 apps

App configurations for kubernetes deployed apps are organized under
`kubernetes/apps`. There are two deployment patterns which are supported for
kubertnetes:

1. kustomize
2. helm


##### kustomize

There are two locations where kustomize manifests are stored:

- `kubernetes/apps/manifests`: holds base kubernetes manifests. These should be
 suiltable to be directly applied using `kubectl apply -f`, but will generally
 be applied using `kubectl apply -k`.
- `kubernetes/apps/overlays`: holds overlays which are based on manifests in
 `kubernetes/apps/manifests`. These are only ever expected be suitable for
 application using `kubectl apply -k`.

When deploying changed kustomize manifests, the ci pipeline will essentially
execute the command:

```bash
kubectl apply -k kubernetes/apps/overlays/$app_name-$release_channel
```

##### helm

There are separate locations for storing embedded helm charts and helm values
files. Not all values files will necessarily have a corresponding chart; some
charts are pulled from external sources.

- charts location: `kubernetes/apps/charts`
- values location: `kubernetes/apps/values`

The pipeline will run a `helm install` or `helm upgrade` command as appropriate
when deploying these applications.

#### 2.2.2 release channels

Each release branch is tied to a specific "release channel", which is simply a
less ambiguous term used to describe an "environment" (e.g., "production", "staging", etc).
There are currently two release branches:

1. `releases/preprod`
2. `releases/prod`

The basename of the branch (i.e., the name after the last "/" character) is used
to determine the name of the release channel being deployed into.

#### 2.2.3 release candidates

Whenever changes to deployment-relevant files (mostly kubernetes yaml files or
ci scripts) are pushed up to a topic branch, it triggers the build of a "release
candidate" branch. This is a special branch which is pruned down to include only
the files which are relevant to performing deployments into release channels. A
deployment should be triggered by pushing or merging a release candidate branch
into a release channel branch.

The release candidate for each topic branch is pushed to
`candidates/$topic_branch_name`.

The release candidate `candidates/main` is the only candidate which should ever
be merged into `releases/prod` and this must be done via PRs.

#### 2.2.4 release configs

Each app has a channel-specific release configuration stored at
`ci/vars/releases/$release_channel-$app_name.env`. This config file informs the
ci pipeline which deployment pattern the app is using and provides helm or
kustomize specific parameters for the deployment.
