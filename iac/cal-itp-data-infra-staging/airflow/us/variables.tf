locals {
  composer_files = setunion(
    fileset("../../../../airflow", "dags/**/*.py"),
    fileset("../../../../airflow", "dags/**/*.yml"),
    fileset("../../../../airflow", "dags/**/*.md"),
    fileset("../../../../airflow", "plugins/**/*.py")
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

data "terraform_remote_state" "networks" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/networks"
  }
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gcs"
  }
}

data "google_storage_bucket_object_content" "calitp-staging-dbt-manifest" {
  name   = "latest/manifest.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_id
}

data "google_storage_bucket_object_content" "calitp-staging-dbt-catalog" {
  name   = "latest/catalog.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_id
}

data "google_storage_bucket_object_content" "calitp-staging-dbt-run_results" {
  name   = "latest/run_results.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_id
}

data "google_storage_bucket_object_content" "calitp-staging-dbt-index" {
  name   = "latest/index.html"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_id
}

data "google_storage_bucket_object_content" "calitp-staging-dbt-partial_parse" {
  name   = "latest/partial_parse.msgpack"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_id
}
