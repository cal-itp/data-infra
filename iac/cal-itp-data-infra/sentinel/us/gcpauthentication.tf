resource "google_project_service" "enable-iam-api" {
  service = "iam.googleapis.com"
  project = data.google_project.project.project_id
}

resource "google_project_service" "enable-cloudresourcemanager-api" {
  service = "cloudresourcemanager.googleapis.com"
  project = data.google_project.project.project_id
}

resource "google_iam_workload_identity_pool" "sentinel-workload-identity-pool" {
  provider                  = google-beta
  project                   = data.google_project.project.project_id
  workload_identity_pool_id = local.workload_identity_pool_id
  display_name              = "sentinel-workload-identity-pool"
  depends_on = [
    google_project_service.enable-cloudresourcemanager-api,
    google_project_service.enable-iam-api
  ]
}

resource "google_iam_workload_identity_pool_provider" "sentinel-workload-identity-pool-provider" {
  provider                           = google-beta
  workload_identity_pool_id          = local.workload_identity_pool_id
  workload_identity_pool_provider_id = "sentinel-identity-provider"
  project                            = data.google_project.project.project_id
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    allowed_audiences = ["api://${local.sentinel_app_id}"]
    issuer_uri        = "https://sts.windows.net/${local.sentinel_auth_id}"
  }
  depends_on = [
    google_iam_workload_identity_pool.sentinel-workload-identity-pool
  ]
}

resource "google_service_account" "sentinel-service-account" {
  account_id   = "sentinel-service-account"
  display_name = "Sentinel Service Account"
  project      = data.google_project.project.project_id
  depends_on = [
    google_project_service.enable-cloudresourcemanager-api,
    google_project_service.enable-iam-api
  ]
}

resource "google_project_iam_custom_role" "sentinel-custom-role" {
  role_id     = "SentinelCustomRole"
  title       = "Sentinel Custom Role"
  description = "Role that allowes pulling messages from pub/sub"
  permissions = ["pubsub.subscriptions.consume", "pubsub.subscriptions.get"]
  project     = data.google_project.project.project_id
}

resource "google_project_iam_member" "bind-sentinel-custom-role-to-sentinel-service-account" {
  provider = google-beta
  project  = data.google_project.project.project_id
  role     = google_project_iam_custom_role.sentinel-custom-role.name

  member = "serviceAccount:${google_service_account.sentinel-service-account.account_id}@${data.google_project.project.project_id}.iam.gserviceaccount.com"
  depends_on = [
    google_service_account.sentinel-service-account
  ]
}

resource "google_service_account_iam_binding" "bind-workloadIdentityUser-role-to-sentinel-service-account" {
  provider           = google-beta
  service_account_id = google_service_account.sentinel-service-account.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${local.workload_identity_pool_id}/*",
  ]
}
