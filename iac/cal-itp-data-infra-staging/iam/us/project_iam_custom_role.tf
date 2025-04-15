resource "google_project_iam_custom_role" "tfer--projects-002F-cal-itp-data-infra-staging-002F-roles-002F-CustomGCSPublisher" {
  description = "Custom role for publishing to GCS"
  permissions = ["resourcemanager.projects.get", "storage.buckets.get", "storage.buckets.list", "storage.objects.create", "storage.objects.delete", "storage.objects.get", "storage.objects.list", "storage.objects.update"]
  project     = "cal-itp-data-infra-staging"
  role_id     = "CustomGCSPublisher"
  stage       = "ALPHA"
  title       = "Custom GCS Publisher"
}

resource "google_project_iam_custom_role" "calitp-dds-analyst" {
  description = "Custom role for DDS Analysts"
  permissions = ["viewer"]
  role_id     = "dds.analyst"
  project     = "cal-itp-data-infra-staging"
  title       = "DDS Analyst"
}
