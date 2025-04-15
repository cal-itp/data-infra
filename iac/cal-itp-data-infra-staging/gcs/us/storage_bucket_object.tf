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
  bucket   = google_storage_bucket.calitp-staging-composer.id
}
