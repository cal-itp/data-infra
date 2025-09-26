locals {
  namespace                  = "airflow-jobs"
  secret                     = "jobs-data"
  kubernetes_service_account = "composer-service-account"

  # This regular expression corresponds to the Python package name specification
  # https://packaging.python.org/en/latest/specifications/name-normalization/
  python_package_regex  = "(?P<name>[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9])(?P<version>.*)"
  requirements_txt_path = abspath("../../../../airflow/requirements.txt")
  requirements = tolist([
    for line in split("\n", trimspace(file(local.requirements_txt_path))) :
    regex(local.python_package_regex, line)
  ])
  pypi_packages = tomap({
    for requirement in local.requirements :
    requirement.name => requirement.version
  })

  env_path = abspath("../../../../airflow/.staging.env")
  env = tolist([
    for line in split("\n", trimspace(file(local.env_path))) :
    regex("(?P<name>[A-Z0-9_]+)=(?P<value>.*)", line)
  ])
  env_variables = tomap({
    for variable in local.env :
    variable.name => variable.value
  })
}

data "kubernetes_secret" "composer" {
  metadata {
    name      = local.secret
    namespace = local.namespace
  }
}


data "google_client_config" "default" {}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gcs"
  }
}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gke"
  }
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}
