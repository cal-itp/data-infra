resource "google_sql_database_instance" "metabase" {
  name                = "metabase"
  database_version    = "POSTGRES_18"
  region              = "us-west2"
  deletion_protection = true

  settings {
    edition = "ENTERPRISE"
    tier    = "db-g1-small"

    backup_configuration {
      location = "us-west2"
      enabled  = true

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
  }
}

resource "google_sql_database" "metabase" {
  name     = "metabase"
  instance = google_sql_database_instance.metabase.name
}

resource "google_sql_user" "metabase" {
  name                = "metabase"
  instance            = google_sql_database_instance.metabase.name
  password_wo         = random_password.metabase-database.result
  password_wo_version = element(split("/", google_secret_manager_secret_version.metabase-password.name), -1)
}
