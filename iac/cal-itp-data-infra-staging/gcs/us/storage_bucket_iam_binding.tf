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

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-amplitude-benefits-events" {
  bucket  = "b/test-calitp-amplitude-benefits-events"
  members = ["projectViewer:cal-itp-data-infra-staging"]
  role    = "roles/storage.legacyBucketReader"
}
