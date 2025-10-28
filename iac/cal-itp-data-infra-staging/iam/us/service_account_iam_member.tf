resource "google_service_account_iam_member" "github-actions-terraform" {
  service_account_id = google_service_account.github-actions-terraform.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-infra_github_repository_name}"
}

resource "google_service_account_iam_member" "github-actions-service-account" {
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-infra_github_repository_name}"
}

resource "google_service_account_iam_member" "github-actions-service-account_cal-bc" {
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.cal-bc_github_repository_name}"
}

resource "google_service_account_iam_member" "custom_service_account" {
  service_account_id = google_service_account.composer-service-account.id
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${local.project_id}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "airflow-jobs_composer-service-account" {
  service_account_id = google_service_account.composer-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:cal-itp-data-infra-staging.svc.id.goog[airflow-jobs/composer-service-account]"
}

resource "google_service_account_iam_member" "enghouse-raw-sftp-service-account" {
  service_account_id = google_service_account.sftp-pod-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:cal-itp-data-infra-staging.svc.id.goog[default/sftp-pod-service-account]"
}

resource "google_service_account_iam_member" "github-actions-service-account_data-analyses" {
  service_account_id = google_service_account.github-actions-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${local.data-analyses_github_repository_name}"
}
