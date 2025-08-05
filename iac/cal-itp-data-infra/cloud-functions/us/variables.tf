variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west2"
}

variable "service_account_email" {
  description = "Service account email for Cloud Function"
  type        = string
  default     = "cal-itp-data-infra@appspot.gserviceaccount.com"
}

variable "source_bucket" {
  description = "GCS bucket containing the function source zip"
  type        = string
}

variable "source_zip" {
  description = "Path to the zip file in the GCS bucket"
  type        = string
}
