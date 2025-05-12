resource "google_storage_bucket_object" "calitp-staging-composer" {
  for_each = local.composer_files
  name     = each.value
  source   = "../../../../airflow/${each.value}"
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-dags" {
  for_each = local.warehouse_files
  name     = "data/warehouse/${each.value}"
  source   = "../../../../warehouse/${each.value}"
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-plugins" {
  for_each = local.composer_plugins_files
  name     = "data/${each.value}"
  source   = "../../../../airflow/${each.value}"
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-manifest" {
  name    = "data/warehouse/target/manifest.json"
  content = data.google_storage_bucket_object_content.calitp-staging-dbt-manifest.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-catalog" {
  name    = "data/warehouse/target/catalog.json"
  content = data.google_storage_bucket_object_content.calitp-staging-dbt-catalog.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-index" {
  name    = "data/warehouse/target/index.html"
  content = data.google_storage_bucket_object_content.calitp-staging-dbt-index.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}

resource "google_storage_bucket_object" "calitp-staging-composer-run_results" {
  name    = "data/warehouse/target/run_results.json"
  content = data.google_storage_bucket_object_content.calitp-staging-dbt-run_results.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}
