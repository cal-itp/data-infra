locals {
  files = setunion(
    fileset("../../../../airflow", "dags/**/*.py"),
    fileset("../../../../airflow", "dags/**/*.yml"),
    fileset("../../../../airflow", "dags/**/*.md"),
    fileset("../../../../airflow", "plugins/**/*.py")
  )
}

resource "google_storage_bucket_object" "calitp-staging-composer" {
  for_each = local.files
  name     = each.value
  source   = each.value
  bucket   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_id
}
