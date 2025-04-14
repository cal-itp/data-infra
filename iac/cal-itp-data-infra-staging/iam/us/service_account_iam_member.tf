locals {
  project_id             = "473674835135"
  github_repository_name = "cal-itp/data-infra"
}

resource "google_service_account_iam_member" "github-actions-terraform" {
  service_account_id = google_service_account.github-actions-terraform.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions--pool.name}/attribute.repository/${local.github_repository_name}"
}

resource "google_service_account_iam_member" "github-actions-service-account" {
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions--pool.name}/attribute.repository/${local.github_repository_name}"
}

resource "google_service_account_iam_member" "custom_service_account" {
  service_account_id = google_service_account.composer-service-account.id
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${local.project_id}@cloudcomposer-accounts.iam.gserviceaccount.com"
}
