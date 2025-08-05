provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud Function v2
resource "google_cloudfunctions2_function" "update_airtable" {
  name     = "update-expired-airtable-issues"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "update_expired_airtable_issues"

    source {
      storage_source {
        bucket = var.source_bucket
        object = var.source_zip
      }
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 540
    service_account_email = var.service_account_email

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

# Optional: Output the function URL
