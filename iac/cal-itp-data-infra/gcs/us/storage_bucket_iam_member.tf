resource "google_storage_bucket_iam_member" "tfer--analysis-output-models" {
  bucket = "b/analysis-output-models"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/artifacts.cal-itp-data-infra.appspot.com"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/cal-itp-data-infra.appspot.com"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-aggregator-scraper" {
  bucket = "b/calitp-aggregator-scraper"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-airtable" {
  bucket = "b/calitp-airtable"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-amplitude-benefits-events" {
  bucket = "b/calitp-amplitude-benefits-events"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-analytics-data" {
  bucket = "b/calitp-analytics-data"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-backups-grafana" {
  bucket = "b/calitp-backups-grafana"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-backups-metabase" {
  bucket = "b/calitp-backups-metabase"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-backups-sentry" {
  bucket = "b/calitp-backups-sentry"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-backups-test" {
  bucket = "b/calitp-backups-test"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-ci-artifacts" {
  bucket = "b/calitp-ci-artifacts"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-dbt-artifacts" {
  bucket = "b/calitp-dbt-artifacts"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-dbt-python-models" {
  bucket = "b/calitp-dbt-python-models"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-elavon-parsed" {
  bucket = "b/calitp-elavon-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-elavon-raw" {
  bucket = "b/calitp-elavon-raw"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-download-config" {
  bucket = "b/calitp-gtfs-download-config"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-rt-parsed" {
  bucket = "b/calitp-gtfs-rt-parsed"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-rt-raw-deprecated" {
  bucket = "b/calitp-gtfs-rt-raw-deprecated"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-rt-raw-v2" {
  bucket = "b/calitp-gtfs-rt-raw-v2"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-rt-validation" {
  bucket = "b/calitp-gtfs-rt-validation"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-parsed" {
  bucket = "b/calitp-gtfs-schedule-parsed"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-parsed-hourly" {
  bucket = "b/calitp-gtfs-schedule-parsed-hourly"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-raw-v2" {
  bucket = "b/calitp-gtfs-schedule-raw-v2"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-unzipped" {
  bucket = "b/calitp-gtfs-schedule-unzipped"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-unzipped-hourly" {
  bucket = "b/calitp-gtfs-schedule-unzipped-hourly"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-validation" {
  bucket = "b/calitp-gtfs-schedule-validation"
  member = "serviceAccount:gtfs-rt-archiver@cal-itp-data-infra.iam.gserviceaccount.com"
  role   = "roles/storage.objectCreator"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-gtfs-schedule-validation-hourly" {
  bucket = "b/calitp-gtfs-schedule-validation-hourly"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-map-tiles" {
  bucket = "b/calitp-map-tiles"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-metabase-data-public" {
  bucket = "b/calitp-metabase-data-public"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-ntd-api-products" {
  bucket = "b/calitp-ntd-api-products"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-ntd-report-validation" {
  bucket = "b/calitp-ntd-report-validation"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-ntd-xlsx-products-clean" {
  bucket = "b/calitp-ntd-xlsx-products-clean"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-ntd-xlsx-products-raw" {
  bucket = "b/calitp-ntd-xlsx-products-raw"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-payments-littlepay-parsed" {
  bucket = "b/calitp-payments-littlepay-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-payments-littlepay-parsed-v3" {
  bucket = "b/calitp-payments-littlepay-parsed-v3"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-payments-littlepay-raw" {
  bucket = "b/calitp-payments-littlepay-raw"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-payments-littlepay-raw-v3" {
  bucket = "b/calitp-payments-littlepay-raw-v3"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-prod-gcp-components-tfstate" {
  bucket = "b/calitp-prod-gcp-components-tfstate"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-publish" {
  bucket = "b/calitp-publish"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-publish-data-analysis" {
  bucket = "b/calitp-publish-data-analysis"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-reports-data" {
  bucket = "b/calitp-reports-data"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-state-geoportal-scrape" {
  bucket = "b/calitp-state-geoportal-scrape"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--calitp-state-highway-network-stops" {
  bucket = "b/calitp-state-highway-network-stops"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--dataproc-staging-us-west2-1005246706141-sfgmtgyp" {
  bucket = "b/dataproc-staging-us-west2-1005246706141-sfgmtgyp"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--dataproc-temp-us-west2-1005246706141-x9mtxbwg" {
  bucket = "b/dataproc-temp-us-west2-1005246706141-x9mtxbwg"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--dev-calitp-aggregator-scraper" {
  bucket = "b/dev-calitp-aggregator-scraper"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--dev-calitp-gtfs-rt-raw" {
  bucket = "b/dev-calitp-gtfs-rt-raw"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--dev-calitp-test-sandbox" {
  bucket = "b/dev-calitp-test-sandbox"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--export-ysjqwvyxc4ti3jmahojq" {
  bucket = "b/export-ysjqwvyxc4ti3jmahojq"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-data" {
  bucket = "b/gtfs-data"
  member = "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
  role   = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-data-reports" {
  bucket = "b/gtfs-data-reports"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-data-test" {
  bucket = "b/gtfs-data-test"
  member = "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-data-test-reports" {
  bucket = "b/gtfs-data-test-reports"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-schedule-backfill-test" {
  bucket = "b/gtfs-schedule-backfill-test"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--gtfs-schedule-backfill-test-deprecated" {
  bucket = "b/gtfs-schedule-backfill-test-deprecated"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--littlepay-data-extract-prod" {
  bucket = "b/littlepay-data-extract-prod"
  member = "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
  role   = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_member" "tfer--rt-parsed" {
  bucket = "b/rt-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--rt-parsed-deprecated" {
  bucket = "b/rt-parsed-deprecated"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--staging-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/staging.cal-itp-data-infra.appspot.com"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-aggregator-scraper" {
  bucket = "b/test-calitp-aggregator-scraper"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-airtable" {
  bucket = "b/test-calitp-airtable"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-dbt-artifacts" {
  bucket = "b/test-calitp-dbt-artifacts"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-dbt-python-models" {
  bucket = "b/test-calitp-dbt-python-models"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-elavon" {
  bucket = "b/test-calitp-elavon"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-elavon-parsed" {
  bucket = "b/test-calitp-elavon-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-elavon-raw" {
  bucket = "b/test-calitp-elavon-raw"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-config" {
  bucket = "b/test-calitp-gtfs-config"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-download-config" {
  bucket = "b/test-calitp-gtfs-download-config"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-raw" {
  bucket = "b/test-calitp-gtfs-raw"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-rt-parsed" {
  bucket = "b/test-calitp-gtfs-rt-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-rt-raw" {
  bucket = "b/test-calitp-gtfs-rt-raw"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-rt-raw-v2" {
  bucket = "b/test-calitp-gtfs-rt-raw-v2"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-rt-validation" {
  bucket = "b/test-calitp-gtfs-rt-validation"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-parsed" {
  bucket = "b/test-calitp-gtfs-schedule-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-parsed-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-parsed-hourly"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-processed" {
  bucket = "b/test-calitp-gtfs-schedule-processed"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-raw" {
  bucket = "b/test-calitp-gtfs-schedule-raw"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-raw-v2" {
  bucket = "b/test-calitp-gtfs-schedule-raw-v2"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-raw-v2-backfill-test" {
  bucket = "b/test-calitp-gtfs-schedule-raw-v2-backfill-test"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-unzipped" {
  bucket = "b/test-calitp-gtfs-schedule-unzipped"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-unzipped-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-unzipped-hourly"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-validation" {
  bucket = "b/test-calitp-gtfs-schedule-validation"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-gtfs-schedule-validation-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-validation-hourly"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-ntd-api-products" {
  bucket = "b/test-calitp-ntd-api-products"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-ntd-report-validation" {
  bucket = "b/test-calitp-ntd-report-validation"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-ntd-xlsx-products-clean" {
  bucket = "b/test-calitp-ntd-xlsx-products-clean"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-ntd-xlsx-products-raw" {
  bucket = "b/test-calitp-ntd-xlsx-products-raw"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-payments-littlepay-parsed" {
  bucket = "b/test-calitp-payments-littlepay-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-payments-littlepay-parsed-v3" {
  bucket = "b/test-calitp-payments-littlepay-parsed-v3"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-payments-littlepay-raw" {
  bucket = "b/test-calitp-payments-littlepay-raw"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-payments-littlepay-raw-v3" {
  bucket = "b/test-calitp-payments-littlepay-raw-v3"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-publish" {
  bucket = "b/test-calitp-publish"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-publish-data-analysis" {
  bucket = "b/test-calitp-publish-data-analysis"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-reports-data" {
  bucket = "b/test-calitp-reports-data"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectReader"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-sentry" {
  bucket = "b/test-calitp-sentry"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-calitp-state-geoportal-scrape" {
  bucket = "b/test-calitp-state-geoportal-scrape"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-rt-parsed" {
  bucket = "b/test-rt-parsed"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketOwner"
}

resource "google_storage_bucket_iam_member" "tfer--test-rt-validations" {
  bucket = "b/test-rt-validations"
  member = "projectOwner:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--us-002E-artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/us.artifacts.cal-itp-data-infra.appspot.com"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--us-west2-calitp-airflow2-pr-171e4e47-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-171e4e47-bucket"
  member = "projectEditor:cal-itp-data-infra"
  role   = "roles/storage.legacyObjectOwner"
}

resource "google_storage_bucket_iam_member" "tfer--us-west2-calitp-airflow2-pr-31e41084-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-31e41084-bucket"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "tfer--us-west2-calitp-airflow2-pr-88ca8ec6-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-88ca8ec6-bucket"
  member = "projectViewer:cal-itp-data-infra"
  role   = "roles/storage.legacyBucketReader"
}

resource "google_storage_bucket_iam_member" "calitp_gtfs_public_web_access" {
  bucket = google_storage_bucket.calitp-gtfs.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
