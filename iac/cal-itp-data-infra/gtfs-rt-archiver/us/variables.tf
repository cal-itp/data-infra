locals {
  source_path  = "${path.module}/../../../../services/gtfs-rt-archiver"
  archive_path = "${path.module}/build/source.zip"

  # Empty cohort means every high-frequency resource has count = 0, so the lane
  # does not exist: no scheduler, no ticks, no workflow executions, no idle
  # instances. "Off" is zero cost, not merely cheap.
  high_frequency_enabled = length(var.high_frequency_cohort) > 0 ? 1 : 0

  # 3s cadence => 20 ticks per minute => range [0, 19] in the clock workflow.
  high_frequency_max_tick_index = 60 / var.high_frequency_cadence_seconds - 1
}

# Deliberately held in this file's `default` rather than a terraform.tfvars: CI
# selects apply targets with files: 'iac/cal-itp-data-infra/**/*.tf'
# (.github/workflows/terraform-apply.yml), so a tfvars-only commit would match
# nothing and silently produce no plan and no apply.
variable "high_frequency_cohort" {
  description = "Download config names to archive on the high-frequency clock. Empty list disables the lane entirely. Time-boxed study use only -- see the runbook in services/gtfs-rt-archiver/README.md."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.high_frequency_cohort) <= 2
    error_message = "The high-frequency cohort is capped at 2 feeds. A larger cohort at this cadence is a cost and agency-load incident, not a study."
  }
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
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/iam"
  }
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}
