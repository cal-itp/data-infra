locals {
  github_repository_name = "cal-itp/data-infra"
}

resource "google_iam_workload_identity_pool" "github-actions--pool" {
  workload_identity_pool_id = "github-actions-pool"
}

resource "google_iam_workload_identity_pool_provider" "github-actions--provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-actions--pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = <<EOT
    attribute.repository == "cal-itp/data-infra"
  EOT
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github-actions--service-account" {
  service_account_id = google_service_account.tfer--terraform.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions--pool.name}/attribute.repository/${local.github_repository_name}"
}

resource "google_service_account_iam_member" "github-actions--github-actions-service-accoun" {
  service_account_id = "projects/cal-itp-data-infra/serviceAccounts/github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions--pool.name}/attribute.repository/${local.github_repository_name}"
}
