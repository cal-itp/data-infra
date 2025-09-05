locals {
  composer_files = setunion(
    fileset("../../../../airflow", "dags/**/*.py"),
    fileset("../../../../airflow", "dags/**/*.yml"),
    fileset("../../../../airflow", "dags/**/*.md"),
    fileset("../../../../airflow", "plugins/**/*.py"),
    fileset("../../../../airflow", "plugins/**/*.jar")
  )

  warehouse_files = setunion(
    fileset("../../../../warehouse", "dbt_project.yml"),
    fileset("../../../../warehouse", "packages.yml"),
    fileset("../../../../warehouse", "profiles.yml"),
    fileset("../../../../warehouse", "macros/**/*"),
    fileset("../../../../warehouse", "models/**/*"),
    fileset("../../../../warehouse", "seeds/**/*"),
    fileset("../../../../warehouse", "tests/**/*")
  )
}

data "google_storage_bucket_object_content" "calitp-dbt-manifest" {
  name   = "manifest.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-docs_name
}

data "google_storage_bucket_object_content" "calitp-dbt-catalog" {
  name   = "catalog.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-docs_name
}

data "google_storage_bucket_object_content" "calitp-dbt-index" {
  name   = "index.html"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-docs_name
}

data "terraform_remote_state" "networks" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/networks"
  }
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}
