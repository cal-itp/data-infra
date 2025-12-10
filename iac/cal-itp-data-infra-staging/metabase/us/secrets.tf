resource "google_secret_manager_secret" "metabase-staging-password" {
  secret_id = "metabase-staging-password"
  replication {
    user_managed {
      replicas {
        location = "us-west2"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "metabase-staging-password" {
  secret         = google_secret_manager_secret.metabase-staging-password.name
  secret_data_wo = random_password.metabase-staging-database.result
}
