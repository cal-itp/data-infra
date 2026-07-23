resource "google_storage_bucket_iam_binding" "tfer--analysis-output-models" {
  bucket  = "b/analysis-output-models"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket  = "b/artifacts.cal-itp-data-infra.appspot.com"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--cal-itp-data-infra-002E-appspot-002E-com" {
  bucket  = "b/cal-itp-data-infra.appspot.com"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-aggregator-scraper" {
  bucket  = "b/calitp-aggregator-scraper"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-airtable" {
  bucket  = "b/calitp-airtable"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-amplitude-benefits-events" {
  bucket  = "b/calitp-amplitude-benefits-events"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-analytics-data" {
  bucket  = "b/calitp-analytics-data"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-backups-grafana" {
  bucket  = "b/calitp-backups-grafana"
  members = ["serviceAccount:backup-grafana@cal-itp-data-infra.iam.gserviceaccount.com"]
  role    = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-backups-metabase" {
  bucket  = "b/calitp-backups-metabase"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-backups-sentry" {
  bucket  = "b/calitp-backups-sentry"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-backups-test" {
  bucket  = "b/calitp-backups-test"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-ci-artifacts" {
  bucket  = "b/calitp-ci-artifacts"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-dbt-artifacts" {
  bucket  = "b/calitp-dbt-artifacts"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-dbt-python-models" {
  bucket  = "b/calitp-dbt-python-models"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-download-config" {
  bucket  = "b/calitp-gtfs-download-config"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-rt-parsed" {
  bucket  = "b/calitp-gtfs-rt-parsed"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-rt-raw-deprecated" {
  bucket  = "b/calitp-gtfs-rt-raw-deprecated"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-rt-raw-v2" {
  bucket  = "b/calitp-gtfs-rt-raw-v2"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-rt-validation" {
  bucket  = "b/calitp-gtfs-rt-validation"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-parsed" {
  bucket  = "b/calitp-gtfs-schedule-parsed"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-parsed-hourly" {
  bucket  = "b/calitp-gtfs-schedule-parsed-hourly"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-raw-v2" {
  bucket  = "b/calitp-gtfs-schedule-raw-v2"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-unzipped" {
  bucket  = "b/calitp-gtfs-schedule-unzipped"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-unzipped-hourly" {
  bucket  = "b/calitp-gtfs-schedule-unzipped-hourly"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-validation" {
  bucket  = "b/calitp-gtfs-schedule-validation"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-gtfs-schedule-validation-hourly" {
  bucket  = "b/calitp-gtfs-schedule-validation-hourly"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-map-tiles" {
  bucket  = "b/calitp-map-tiles"
  members = ["allUsers"]
  role    = "roles/storage.objectViewer"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-metabase-data-public" {
  bucket  = "b/calitp-metabase-data-public"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-ntd-api-products" {
  bucket  = "b/calitp-ntd-api-products"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-ntd-report-validation" {
  bucket  = "b/calitp-ntd-report-validation"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-ntd-xlsx-products-clean" {
  bucket  = "b/calitp-ntd-xlsx-products-clean"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-ntd-xlsx-products-raw" {
  bucket  = "b/calitp-ntd-xlsx-products-raw"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-payments-littlepay-parsed" {
  bucket  = "b/calitp-payments-littlepay-parsed"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-payments-littlepay-parsed-v3" {
  bucket  = "b/calitp-payments-littlepay-parsed-v3"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-payments-littlepay-raw" {
  bucket  = "b/calitp-payments-littlepay-raw"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-payments-littlepay-raw-v3" {
  bucket  = "b/calitp-payments-littlepay-raw-v3"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-prod-gcp-components-tfstate" {
  bucket  = "b/calitp-prod-gcp-components-tfstate"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-publish" {
  bucket  = "b/calitp-publish"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-publish-data-analysis" {
  bucket  = "b/calitp-publish-data-analysis"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-reports-data" {
  bucket  = "b/calitp-reports-data"
  members = ["serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"]
  role    = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-state-geoportal-scrape" {
  bucket  = "b/calitp-state-geoportal-scrape"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--calitp-state-highway-network-stops" {
  bucket  = "b/calitp-state-highway-network-stops"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--dataproc-staging-us-west2-1005246706141-sfgmtgyp" {
  bucket  = "b/dataproc-staging-us-west2-1005246706141-sfgmtgyp"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--dataproc-temp-us-west2-1005246706141-x9mtxbwg" {
  bucket  = "b/dataproc-temp-us-west2-1005246706141-x9mtxbwg"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--dev-calitp-gtfs-rt-raw" {
  bucket  = "b/dev-calitp-gtfs-rt-raw"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--export-ysjqwvyxc4ti3jmahojq" {
  bucket  = "b/export-ysjqwvyxc4ti3jmahojq"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--gtfs-data" {
  bucket  = "b/gtfs-data"
  members = ["projectViewer:cal-itp-data-infra", "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com", "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--gtfs-data-reports" {
  bucket  = "b/gtfs-data-reports"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--gtfs-data-test" {
  bucket  = "b/gtfs-data-test"
  members = ["serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com", "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"]
  role    = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_binding" "tfer--littlepay-data-extract-prod" {
  bucket  = "b/littlepay-data-extract-prod"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--rt-parsed" {
  bucket  = "b/rt-parsed"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--rt-parsed-deprecated" {
  bucket  = "b/rt-parsed-deprecated"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--staging-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket  = "b/staging.cal-itp-data-infra.appspot.com"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-airtable" {
  bucket  = "b/test-calitp-airtable"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-dbt-python-models" {
  bucket  = "b/test-calitp-dbt-python-models"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-gtfs-download-config" {
  bucket  = "b/test-calitp-gtfs-download-config"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-gtfs-rt-raw" {
  bucket  = "b/test-calitp-gtfs-rt-raw"
  members = ["serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"]
  role    = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-gtfs-schedule-raw" {
  bucket  = "b/test-calitp-gtfs-schedule-raw"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-gtfs-schedule-raw-v2" {
  bucket  = "b/test-calitp-gtfs-schedule-raw-v2"
  members = ["projectViewer:cal-itp-data-infra", "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--test-calitp-sentry" {
  bucket  = "b/test-calitp-sentry"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--us-002E-artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket  = "b/us.artifacts.cal-itp-data-infra.appspot.com"
  members = ["projectViewer:cal-itp-data-infra"]
  role    = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_binding" "tfer--us-west2-calitp-airflow2-pr-171e4e47-bucket" {
  bucket  = "b/us-west2-calitp-airflow2-pr-171e4e47-bucket"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--us-west2-calitp-airflow2-pr-31e41084-bucket" {
  bucket  = "b/us-west2-calitp-airflow2-pr-31e41084-bucket"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra", "serviceAccount:composer2-service-account@cal-itp-data-infra.iam.gserviceaccount.com"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "tfer--us-west2-calitp-airflow2-pr-88ca8ec6-bucket" {
  bucket  = "b/us-west2-calitp-airflow2-pr-88ca8ec6-bucket"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "calitp-composer3" {
  bucket  = google_storage_bucket.calitp-composer3.name
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra", "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_email}"]
  role    = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_binding" "calitp-tides" {
  bucket  = "calitp-tides"
  members = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role    = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "calitp" {
  for_each = local.environment_buckets
  bucket   = google_storage_bucket.calitp[each.key].name
  members  = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role     = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_binding" "calitp-site" {
  for_each = local.site_buckets
  bucket   = google_storage_bucket.calitp-site[each.key].name
  members  = ["projectEditor:cal-itp-data-infra", "projectOwner:cal-itp-data-infra"]
  role     = "roles/storage.legacyObjectOwner"
}
