resource "google_sql_database_instance" "metabase-staging" {
  name                = "metabase-staging"
  database_version    = "POSTGRES_18"
  region              = "us-west2"
  deletion_protection = true

  settings {
    edition = "ENTERPRISE"
    tier    = "db-f1-micro"

    backup_configuration {
      location = "us"
      enabled  = true

      backup_retention_settings {
        retained_backups = 60
        retention_unit   = "COUNT"
      }
    }
  }
}

resource "google_sql_database" "metabase-staging" {
  name     = "metabase-staging"
  instance = google_sql_database_instance.metabase-staging.name
}

resource "google_sql_user" "metabase-staging" {
  name                = "metabase-staging"
  instance            = google_sql_database_instance.metabase-staging.name
  password_wo         = random_password.metabase-staging-database.result
  password_wo_version = element(split("/", google_secret_manager_secret_version.metabase-staging-password.name), -1)
}
