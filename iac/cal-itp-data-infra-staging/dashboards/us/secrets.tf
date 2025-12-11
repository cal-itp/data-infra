resource "google_secret_manager_secret" "metabase-api-key" {
  secret_id = "metabase-api-key"
  replication {
    user_managed {
      replicas {
        location = "us-west2"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "metabase-api-key" {
  secret = google_secret_manager_secret.metabase-api-key.name
}
