resource "google_storage_bucket" "jamesl-deleteme" {
  name          = "jamesl-deleteme"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}
