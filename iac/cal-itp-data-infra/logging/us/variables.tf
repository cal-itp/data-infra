data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}

locals {
  gtfs_rt_raw_v2_bucket_name = data.terraform_remote_state.gcs.outputs["google_storage_bucket_tfer--calitp-gtfs-rt-raw-v2_name"]
}
