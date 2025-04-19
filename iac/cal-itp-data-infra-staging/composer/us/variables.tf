locals {
  requirements_txt_path = abspath("../../../../airflow/requirements.txt")
  requirements = tolist([
    for line in split("\n", trimspace(file(local.requirements_txt_path))):
      regex("(?P<name>[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9])(?P<version>.*)", line)
  ])
  pypi_packages = tomap({
    for requirement in local.requirements:
      requirement.name => requirement.version
  })
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gcs"
  }
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}
