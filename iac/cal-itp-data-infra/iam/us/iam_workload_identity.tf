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
    issuer_uri                       = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github-actions--service-account" {
  service_account_id = google_service_account.tfer--104433253766206552796.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/1005246706141/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github-actions--pool.workload_identity_pool_id}/attribute.repository/cal-itp/data-infra"
}
