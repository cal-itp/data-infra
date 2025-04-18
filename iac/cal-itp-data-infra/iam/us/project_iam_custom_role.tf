resource "google_project_iam_custom_role" "tfer--projects-002F-cal-itp-data-infra-002F-roles-002F-AgencyPaymentsServiceReader" {
  description = "Created on: 2022-08-29 Based on: BigQuery Data Viewer, BigQuery Job User, BigQuery Metadata Viewer"
  permissions = ["bigquery.config.get",
    "bigquery.datasets.get",
    "bigquery.datasets.getIamPolicy",
    "bigquery.jobs.create",
    "bigquery.models.export",
    "bigquery.models.getData",
    "bigquery.models.getMetadata",
    "bigquery.models.list",
    "bigquery.routines.get",
    "bigquery.routines.list",
    "bigquery.tables.createSnapshot",
    "bigquery.tables.export",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.getIamPolicy",
    "bigquery.tables.list",
    "resourcemanager.projects.get"
  ]
  project = "cal-itp-data-infra"
  role_id = "AgencyPaymentsServiceReader"
  stage   = "GA"
  title   = "Agency Payments Service Reader"
}

resource "google_project_iam_custom_role" "tfer--projects-002F-cal-itp-data-infra-002F-roles-002F-DataAnalyst" {
  description = "Access to view GCS, admin on analysis bucket, and BigQuery user"
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
    "bigquery.models.list",
    "bigquery.readsessions.create",
    "bigquery.readsessions.getData",
    "bigquery.readsessions.update",
    "bigquery.reservationAssignments.list",
    "bigquery.reservationAssignments.search",
    "bigquery.reservations.get",
    "bigquery.reservations.list",
    "bigquery.routines.list",
    "bigquery.savedqueries.get",
    "bigquery.savedqueries.list",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.list",
    "resourcemanager.projects.get",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list"
  ]
  project = "cal-itp-data-infra"
  role_id = "DataAnalyst"
  stage   = "ALPHA"
  title   = "Data Analyst"
}
