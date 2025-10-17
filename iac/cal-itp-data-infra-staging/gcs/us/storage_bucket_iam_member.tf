resource "google_storage_bucket_iam_member" "tfer--calitp-staging-data-analyses-portfolio" {
  bucket = "b/calitp-staging-data-analyses-portfolio"
  member = "projectEditor:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  bucket = "b/calitp-staging-data-analyses-portfolio-draft"
  member = "projectViewer:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  bucket = "b/dataproc-staging-us-west2-473674835135-t87wkokr"
  member = "projectViewer:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  bucket = "b/dataproc-temp-us-west2-473674835135-yuzmmdyk"
  member = "projectEditor:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-staging-gcp-components-tfstate" {
  bucket = "b/calitp-staging-gcp-components-tfstate"
  member = "projectViewer:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "calitp-staging-dbt-docs" {
  bucket = google_storage_bucket.calitp-staging-dbt-docs.name
  member = "allUsers"
  role   = "roles/storage.objectViewer"
}

resource "google_storage_bucket_iam_member" "calitp-staging-composer" {
  bucket = google_storage_bucket.calitp-staging-composer.name
  member = "projectEditor:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "cal-bc-service-account" {
  bucket = google_storage_bucket.calitp-staging-cal-bc.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_cal-bc-service-account_email}"
}

resource "google_storage_bucket_iam_member" "enghouse-raw-sftp-service-account" {
  bucket = google_storage_bucket.cal-itp-data-infra-enghouse-raw.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_sftp-pod-service-account_email}"
}

resource "google_storage_bucket_iam_member" "calitp-staging-pytest" {
  bucket = google_storage_bucket.calitp-staging-pytest.name
  member = "projectViewer:cal-itp-data-infra-staging"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "calitp-staging" {
  for_each = local.environment_buckets
  bucket   = google_storage_bucket.calitp-staging[each.key].name
  member   = "projectViewer:cal-itp-data-infra-staging"
  role     = "roles/storage.legacyBucketReader"
}
