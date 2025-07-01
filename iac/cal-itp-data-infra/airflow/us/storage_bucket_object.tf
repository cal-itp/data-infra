resource "google_storage_bucket_object" "calitp-composer" {
  for_each = local.composer_files
  name     = each.value
  source   = "../../../../airflow/${each.value}"
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}

resource "google_storage_bucket_object" "calitp-composer-dags" {
  for_each = local.warehouse_files
  name     = "data/warehouse/${each.value}"
  source   = "../../../../warehouse/${each.value}"
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}

resource "google_storage_bucket_object" "calitp-composer-manifest" {
  name    = "data/warehouse/target/manifest.json"
  content = data.google_storage_bucket_object_content.calitp-dbt-manifest.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}

resource "google_storage_bucket_object" "calitp-composer-catalog" {
  name    = "data/warehouse/target/catalog.json"
  content = data.google_storage_bucket_object_content.calitp-dbt-catalog.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}

resource "google_storage_bucket_object" "calitp-composer-index" {
  name    = "data/warehouse/target/index.html"
  content = data.google_storage_bucket_object_content.calitp-dbt-index.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}

resource "google_storage_bucket_object" "calitp-composer-partial_parse" {
  name    = "data/warehouse/target/partial_parse.msgpack"
  content = data.google_storage_bucket_object_content.calitp-dbt-partial_parse.content
  bucket  = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
}
