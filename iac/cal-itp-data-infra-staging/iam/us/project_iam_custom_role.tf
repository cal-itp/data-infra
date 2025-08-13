resource "google_project_iam_custom_role" "tfer--projects-002F-cal-itp-data-infra-staging-002F-roles-002F-CustomGCSPublisher" {
  description = "Custom role for publishing to GCS"
  permissions = [
    "resourcemanager.projects.get",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update"
  ]
  project = "cal-itp-data-infra-staging"
  role_id = "CustomGCSPublisher"
  stage   = "ALPHA"
  title   = "Custom GCS Publisher"
}

resource "google_project_iam_custom_role" "calitp-dds-analyst" {
  # Contain some permissions from the following roles:
  # - roles/viewer
  # - roles/bigquery.user
  # - roles/bigquery.metadataViewer
  # - roles/bigquery.filteredDataViewer
  description = "Custom role for DDS Analysts"
  permissions = [
    "bigquery.bireservations.get",
    "bigquery.capacityCommitments.get",
    "bigquery.capacityCommitments.list",
    "bigquery.config.get",
    "bigquery.datasets.create",
    "bigquery.datasets.get",
    "bigquery.datasets.getIamPolicy",
    "bigquery.jobs.create",
    "bigquery.jobs.list",
    "bigquery.jobs.listAll",
    "bigquery.models.list",
    "bigquery.models.getMetadata",
    "bigquery.readsessions.create",
    "bigquery.readsessions.getData",
    "bigquery.readsessions.update",
    "bigquery.reservationAssignments.list",
    "bigquery.reservationAssignments.search",
    "bigquery.reservations.get",
    "bigquery.reservations.list",
    "bigquery.routines.get",
    "bigquery.routines.list",
    "bigquery.savedqueries.get",
    "bigquery.savedqueries.list",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.getIamPolicy",
    "bigquery.tables.list",
    "bigquery.tables.create",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "dataform.locations.get",
    "dataform.locations.list",
    "dataform.repositories.create",
    "dataform.repositories.list",
    "dataplex.projects.search",
    "resourcemanager.projects.get",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list"
  ]
  role_id = "DDSAnalyst"
  project = "cal-itp-data-infra-staging"
  title   = "DDS Analyst"
}

resource "google_project_iam_custom_role" "metabase_additional" {
  description = "Extra permission to view all BigQuery query jobs for cost estimation"
  permissions = [
    "bigquery.jobs.listAll"
  ]
  project = "cal-itp-data-infra-staging"
  role_id = "MetabaseAdditional"
  stage   = "GA"
  title   = "Metabase additional custom permission jobs.listAll"
}
