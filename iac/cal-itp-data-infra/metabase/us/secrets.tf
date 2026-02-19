resource "google_secret_manager_secret" "metabase-password" {
  secret_id = "metabase-password"
  replication {
    user_managed {
      replicas {
        location = "us-west2"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "metabase-password" {
  secret         = google_secret_manager_secret.metabase-password.name
  secret_data_wo = random_password.metabase-database.result
}
