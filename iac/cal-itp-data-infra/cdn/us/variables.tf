data "terraform_remote_state" "networks" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/networks"
  }
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}
