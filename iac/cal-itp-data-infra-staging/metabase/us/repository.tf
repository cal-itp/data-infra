resource "google_artifact_registry_repository" "ghcr" {
  location               = "us-west2"
  repository_id          = "ghcr"
  format                 = "DOCKER"
  mode                   = "REMOTE_REPOSITORY"
  cleanup_policy_dry_run = true

  remote_repository_config {
    description = "GitHub Container Repository"
    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }
  }
}
