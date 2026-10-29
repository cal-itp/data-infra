locals {
  source_path  = "${path.module}/../../../../services/gtfs-rt-archiver"
  archive_path = "${path.module}/build/source.zip"

  # The high-frequency lane ships its own copy of the archiver so that changes for
  # a study never alter the code the standard archiver runs.
  hf_source_path  = "${path.module}/../../../../services/gtfs-rt-archiver-high-frequency"
  hf_archive_path = "${path.module}/build/source-high-frequency.zip"

  # Off means every high-frequency resource except the two buckets has count = 0,
  # so the lane does not exist: no scheduler, no ticks, no workflow executions, no
  # idle instances. "Off" is zero cost, not merely cheap.
  high_frequency_count = var.high_frequency_enabled ? 1 : 0

  # 3s cadence => 20 ticks per minute => range [0, 19] in the clock workflow.
  high_frequency_max_tick_index = 60 / var.high_frequency_cadence_seconds - 1
}

# Deliberately held in this file's `default` rather than a terraform.tfvars: CI
# selects apply targets with files: 'iac/cal-itp-data-infra-staging/**/*.tf'
# (.github/workflows/terraform-apply.yml), so a tfvars-only commit would match
# nothing and silently produce no plan and no apply.
#
# Which feeds the lane archives is not set here: it is the hand-maintained
# download config in the high-frequency config bucket, which changes without a PR.
# See services/gtfs-rt-archiver-high-frequency/README.md.
variable "high_frequency_enabled" {
  description = "Whether the high-frequency archiver lane exists. Seed the config bucket before turning it on."
  type        = bool
  default     = false
}

variable "high_frequency_cadence_seconds" {
  description = "Seconds between high-frequency ticks."
  type        = number
  default     = 3

  validation {
    condition     = var.high_frequency_cadence_seconds >= 3 && 60 % var.high_frequency_cadence_seconds == 0
    error_message = "Cadence must be at least 3 seconds and divide evenly into 60. Below 3s the clock would exceed the Workflows concurrent-iteration limit."
  }
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gcs"
  }
}
