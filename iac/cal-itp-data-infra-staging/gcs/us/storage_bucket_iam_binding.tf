resource "google_storage_bucket_iam_binding" "tfer--calitp-staging-data-analyses-portfolio" {
  bucket  = "b/calitp-staging-data-analyses-portfolio"
  members = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  bucket  = "b/calitp-staging-data-analyses-portfolio-draft"
  members = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  bucket  = "b/dataproc-staging-us-west2-473674835135-t87wkokr"
  members = ["projectViewer:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  bucket  = "b/dataproc-temp-us-west2-473674835135-yuzmmdyk"
  members = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-staging-gcp-components-tfstate" {
  bucket  = "b/calitp-staging-gcp-components-tfstate"
  members = ["projectViewer:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "calitp-staging-composer-composer-service-account" {
  bucket  = google_storage_bucket.calitp-staging-composer.name
  members = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging", "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_email}"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "calitp-staging-pytest" {
  bucket  = google_storage_bucket.calitp-staging-pytest.name
  members = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "calitp-staging" {
  for_each = local.environment_buckets
  bucket   = google_storage_bucket.calitp-staging[each.key].name
  members  = ["projectEditor:cal-itp-data-infra-staging", "projectOwner:cal-itp-data-infra-staging"]
  role     = "roles/storage.legacyObjectOwner"
}
