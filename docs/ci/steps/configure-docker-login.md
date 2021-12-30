# configure-docker-login

Setup authentication to a remote docker registry using `docker login` with
automatic recognition of and special handling for GCR and ECR registries.

## Variables

- `BUILD_REPO`: An image repository name as used by `build-docker-image`. The
 remote registry domain and port will be extracted from this value. The step
 will also use the value of this variable to detect an ECR or GCR registry and
 activate special logic branches as needed.
- `BUILD_REPO_USER`: The registry username as passed to `docker login -u`. This
 value is ignored for GCR registries and hard coded to "AWS" for ECR registries.
- `BUILD_REPO_SECRET`: The registry password as passed to `docker login
 --password-stdin`. This value is ignored for GCR registries and will be
 auto-populated from `aws ecr get-login-password` for ECR registries.

## GCR Additional Notes

Ensure a GCP login has been performed with `gcloud auth login` and the correct
project is selected with `gcloud config set project` prior to running this step.

## ECR Additional notes

Ensure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set appropriately
prior to running this step.
