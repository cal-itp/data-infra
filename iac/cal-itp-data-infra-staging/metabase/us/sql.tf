resource "google_sql_database_instance" "metabase-staging" {
  name             = "metabase-staging"
  database_version = "POSTGRES_14"
  region           = "us-west2"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = true
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
