resource "google_service_account_iam_member" "github-actions-terraform" {
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-infra_github_repository_name}"
  service_account_id = google_service_account.github-actions-terraform.id
  role               = "roles/iam.workloadIdentityUser"
}

resource "google_service_account_iam_member" "github-actions-service-account_data-infra" {
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-infra_github_repository_name}"
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
}

resource "google_service_account_iam_member" "github-actions-service-account_gtfs-calitp-org" {
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.gtfs-calitp-org_github_repository_name}"
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
}

resource "google_service_account_iam_member" "github-actions--github-actions-services-accoun" {
  service_account_id = "projects/cal-itp-data-infra/serviceAccounts/github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-infra_github_repository_name}"
}
