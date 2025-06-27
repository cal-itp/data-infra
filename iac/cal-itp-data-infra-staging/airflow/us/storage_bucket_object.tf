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

resource "google_storage_bucket_object" "calitp-staging-composer-partial_parse" {
  name    = "data/warehouse/target/partial_parse.msgpack"
  content = data.google_storage_bucket_object_content.calitp-staging-dbt-partial_parse.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}
