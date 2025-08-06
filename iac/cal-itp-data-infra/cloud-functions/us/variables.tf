variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "cal-itp-data-infra"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west2"
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}
