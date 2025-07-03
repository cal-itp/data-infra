resource "google_iam_workload_identity_pool" "github-actions" {
  workload_identity_pool_id = "github-actions"
}

resource "google_iam_workload_identity_pool_provider" "data-infra" {
  workload_identity_pool_provider_id = "data-infra"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-actions.workload_identity_pool_id
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = <<EOT
    attribute.repository == "${local.data-infra_github_repository_name}"
  EOT
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "gtfs-calitp-org" {
  workload_identity_pool_provider_id = "gtfs-calitp-org"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-actions.workload_identity_pool_id
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = <<EOT
    attribute.repository == "${local.gtfs-calitp-org_github_repository_name}"
  EOT
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "reports" {
  workload_identity_pool_provider_id = "reports"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-actions.workload_identity_pool_id
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = <<EOT
    attribute.repository == "${local.reports_github_repository_name}"
  EOT
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
