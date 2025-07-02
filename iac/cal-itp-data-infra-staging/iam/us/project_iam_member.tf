resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-dataEditorserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.dataEditor"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-dataEditorserviceAccount-003A-github-actions-services-accoun-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.dataEditor"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-dataViewerserviceAccount-003A-github-actions-services-accoun-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.dataViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-dataViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.dataViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-dataViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.dataViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-jobUserserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-jobUserserviceAccount-003A-calitp-py-ci-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-jobUserserviceAccount-003A-github-actions-services-accoun-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-jobUserserviceAccount-003A-metabase-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-jobUserserviceAccount-003A-metabase-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-metadataViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.metadataViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-metadataViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.metadataViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-readSessionUserserviceAccount-003A-github-actions-services-accoun-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.readSessionUser"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-userserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.user"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-userserviceAccount-003A-calitp-py-ci-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.user"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquery-002E-userserviceAccount-003A-github-actions-services-accoun-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquery.user"
}

resource "google_project_iam_member" "tfer--roles-002F-bigquerydatatransfer-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-gcp-sa-bigquerydatatransfer-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/bigquerydatatransfer.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-cloudbuild-002E-builds-002E-builderserviceAccount-003A-473674835135-0040-cloudbuild-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:473674835135@cloudbuild.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/cloudbuild.builds.builder"
}

resource "google_project_iam_member" "tfer--roles-002F-cloudbuild-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-gcp-sa-cloudbuild-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/cloudbuild.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-composer-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-cloudcomposer-accounts-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@cloudcomposer-accounts.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/composer.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-compute-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-compute-system-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@compute-system.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/compute.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-container-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-container-engine-robot-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@container-engine-robot.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/container.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-containerregistry-002E-ServiceAgentserviceAccount-003A-service-473674835135-0040-containerregistry-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@containerregistry.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/containerregistry.ServiceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-dataproc-002E-editorserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/dataproc.editor"
}

resource "google_project_iam_member" "tfer--roles-002F-dataproc-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-dataproc-accounts-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@dataproc-accounts.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/dataproc.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-dataproc-002E-workerserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/dataproc.worker"
}

resource "google_project_iam_member" "tfer--roles-002F-editorserviceAccount-003A-473674835135-0040-cloudservices-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:473674835135@cloudservices.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/editor"
}

resource "google_project_iam_member" "tfer--roles-002F-editorserviceAccount-003A-473674835135-compute-0040-developer-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:473674835135-compute@developer.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/editor"
}

resource "google_project_iam_member" "tfer--roles-002F-iam-002E-serviceAccountUserserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/iam.serviceAccountUser"
}

resource "google_project_iam_member" "tfer--roles-002F-ownerserviceAccount-003A-amplitude-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:amplitude@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/owner"
}

resource "google_project_iam_member" "tfer--roles-002F-ownerserviceAccount-003A-local-airflow-dev-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:local-airflow-dev@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/owner"
}

resource "google_project_iam_member" "tfer--roles-002F-pubsub-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-gcp-sa-pubsub-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@gcp-sa-pubsub.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/pubsub.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-servicenetworking-002E-serviceAgentserviceAccount-003A-service-473674835135-0040-gcp-sa-cloudasset-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@gcp-sa-cloudasset.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/servicenetworking.serviceAgent"
}

resource "google_project_iam_member" "tfer--roles-002F-storage-002E-objectAdminserviceAccount-003A-bq-transform-svcacct-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/storage.objectAdmin"
}

resource "google_project_iam_member" "tfer--roles-002F-storage-002E-objectAdminserviceAccount-003A-service-473674835135-0040-gcp-sa-cloudasset-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:service-473674835135@gcp-sa-cloudasset.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/storage.objectAdmin"
}

resource "google_project_iam_member" "tfer--roles-002F-storage-002E-objectViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/storage.objectViewer"
}

resource "google_project_iam_member" "tfer--roles-002F-storage-002E-objectViewerserviceAccount-003A-metabase-0040-cal-itp-data-infra-staging-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:metabase@cal-itp-data-infra-staging.iam.gserviceaccount.com"
  project = "cal-itp-data-infra-staging"
  role    = "roles/storage.objectViewer"
}

resource "google_project_iam_member" "github-actions-terraform" {
  for_each = toset([
    "roles/resourcemanager.projectIamAdmin",
    "roles/bigquery.dataOwner",
    "roles/editor",
    "roles/storage.admin",
    "roles/iam.roleAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/logging.configWriter"
  ])
  role    = each.key
  member  = "serviceAccount:${google_service_account.github-actions-terraform.email}"
  project = "cal-itp-data-infra-staging"
}

resource "google_project_iam_member" "github-actions-service-account" {
  for_each = toset([
    "roles/viewer",
    "roles/bigquery.user",
    "roles/bigquery.dataOwner",
    "roles/bigquery.filteredDataViewer",
    "roles/bigquery.metadataViewer",
    "roles/composer.admin",
    "roles/storage.objectAdmin",
    google_project_iam_custom_role.calitp-dds-analyst.id,
    google_project_iam_custom_role.tfer--projects-002F-cal-itp-data-infra-staging-002F-roles-002F-CustomGCSPublisher.id
  ])
  role    = each.key
  member  = "serviceAccount:${google_service_account.github-actions-service-account.email}"
  project = "cal-itp-data-infra-staging"
}

resource "google_project_iam_member" "composer-service-account" {
  for_each = toset([
    "roles/bigquery.dataOwner",
    "roles/bigquery.jobUser",
    "roles/cloudbuild.builds.viewer",
    "roles/composer.ServiceAgentV2Ext",
    "roles/composer.serviceAgent",
    "roles/composer.worker",
    "roles/secretmanager.secretAccessor",
    "roles/secretmanager.viewer"
  ])
  role    = each.key
  member  = "serviceAccount:${google_service_account.composer-service-account.email}"
  project = "cal-itp-data-infra-staging"
}

resource "google_project_iam_member" "ms-entra-id-DOT_DDS_Data_Pipeline_and_Warehouse_Users" {
  for_each = toset([
    "roles/viewer",
    "roles/bigquery.user",
    "roles/bigquery.dataEditor",
    "roles/bigquery.filteredDataViewer",
    "roles/storage.objectUser",
    "roles/secretmanager.secretAccessor",
    "roles/secretmanager.viewer",
    google_project_iam_custom_role.calitp-dds-analyst.id
  ])
  role    = each.key
  member  = "principalSet://iam.googleapis.com/locations/global/workforcePools/dot-ca-gov/group/DOT_DDS_Data_Pipeline_and_Warehouse_Users"
  project = "cal-itp-data-infra-staging"
}

resource "google_project_iam_member" "ms-entra-id-DDS_Cloud_Admins" {
  for_each = toset([
    "roles/editor",
    "roles/bigquery.admin",
    "roles/bigquery.dataEditor",
    "roles/storage.objectAdmin",
    "roles/composer.admin",
    "roles/secretmanager.admin",
    google_project_iam_custom_role.calitp-dds-analyst.id
  ])
  role    = each.key
  member  = "principalSet://iam.googleapis.com/locations/global/workforcePools/dot-ca-gov/group/DDS_Cloud_Admins"
  project = "cal-itp-data-infra-staging"
}
