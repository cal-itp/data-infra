locals {
  source_zip            = "update-expired-airtable-issues.zip"
  function_source_dir   = "${path.module}/../../../../cloud-functions/update-expired-airtable-issues"
  service_account_email = "cal-itp-data-infra@appspot.gserviceaccount.com"
}

# resource "null_resource" "zip_update_expired_airtable_issues" {
#   # triggers = {
#   #   files  = sha1(join("", fileset(local.function_source_dir, "*")))
#   # }
#
#   provisioner "local-exec" {
#     command = <<EOT
#       cd ${local.function_source_dir}
#       zip -r ${local.source_zip} main.py requirements.txt *.sql
#     EOT
#   }
# }

data "archive_file" "zip_update_expired_airtable_issues" {
  type             = "zip"
  source_dir       = local.function_source_dir
  output_path      = local.source_zip
  output_file_mode = "0666"
}

resource "google_storage_bucket_object" "update-expired-airtable-issues" {
  name                = local.source_zip
  bucket              = data.terraform_remote_state.gcs.outputs.google_storage_bucket_cal-itp-data-infra-cf-source_name
  source              = local.source_zip
  content_disposition = "attachment"
  content_type        = "application/zip"
  depends_on          = [data.archive_file.zip_update_expired_airtable_issues]

  provisioner "local-exec" {
    when    = create
    command = "rm ${data.archive_file.zip_update_expired_airtable_issues.output_path}"
  }
}

resource "google_cloudfunctions2_function" "update_expired_airtable_issues" {
  name     = "update-expired-airtable-issues-tf2"
  location = var.region

  depends_on = [google_storage_bucket_object.update-expired-airtable-issues]

  build_config {
    runtime     = "python311"
    entry_point = "update_expired_airtable_issues"

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_cal-itp-data-infra-cf-source_name
        object = local.source_zip
      }
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 540
    service               = "update-expired-airtable-issues-tf-service" # <-- UNIQUE NAME
    service_account_email = local.service_account_email

    # Secrets from Secret Manager
    secret_environment_variables {
      key        = "F_AIRTABLE_TOKEN"
      project_id = var.project_id
      secret     = "F_AIRTABLE_TOKEN"
      version    = "latest"
    }
    secret_environment_variables {
      key        = "F_EMAIL_WORD"
      project_id = var.project_id
      secret     = "F_EMAIL_WORD"
      version    = "latest"
    }
    secret_environment_variables {
      key        = "F_SENDER_EMAIL"
      project_id = var.project_id
      secret     = "F_SENDER_EMAIL"
      version    = "latest"
    }
  }
}

# -----------------------
# Cloud Scheduler Job
# -----------------------
resource "google_cloud_scheduler_job" "update_expired_airtable_issues" {
  name        = "update-expired-airtable-issues-tf-job"
  description = "Trigger Cloud Function weekly on Fridays at 5 AM PST"
  schedule    = "0 5 * * 5" # Friday 5 AM PST
  time_zone   = "America/Los_Angeles"
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.update_expired_airtable_issues.service_config[0].uri

    oidc_token {
      service_account_email = local.service_account_email
    }
  }

  depends_on = [
    google_cloudfunctions2_function.update_expired_airtable_issues
  ]
}
