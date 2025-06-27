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

data "google_storage_bucket_object_content" "calitp-dbt-manifest" {
  name   = "latest/manifest.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_tfer--calitp-dbt-artifacts_name
}

data "google_storage_bucket_object_content" "calitp-dbt-catalog" {
  name   = "latest/catalog.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_tfer--calitp-dbt-artifacts_name
}

data "google_storage_bucket_object_content" "calitp-dbt-run_results" {
  name   = "latest/run_results.json"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_tfer--calitp-dbt-artifacts_name
}

data "google_storage_bucket_object_content" "calitp-dbt-index" {
  name   = "latest/index.html"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_tfer--calitp-dbt-artifacts_name
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
