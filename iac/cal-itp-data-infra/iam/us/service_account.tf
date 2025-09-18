resource "google_service_account" "tfer--100119052859631924010" {
  account_id = "ccjpa-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--100409301237368942133" {
  account_id   = "backup-sentry"
  disabled     = "false"
  display_name = "backup-sentry"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--100825686811848658754" {
  account_id   = "dev-gtfs-rt-archiver-v3"
  disabled     = "false"
  display_name = "dev-gtfs-rt-archiver-v3"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--101531038543713191301" {
  account_id   = "gtfs-rt-archiver-v3"
  description  = "Reads config data from and writes data back out to GCS"
  disabled     = "false"
  display_name = "gtfs-rt-archiver-v3"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--102313012674966610402" {
  account_id   = "metabase-backup"
  description  = "LEGACY ACCOUNT -- PLEASE USE backup-preprod INSTEAD"
  disabled     = "false"
  display_name = "metabase-backup"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--102898235871657893180" {
  account_id   = "cal-itp-data-infra"
  disabled     = "false"
  display_name = "App Engine default service account"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--103282778270991614945" {
  account_id   = "composer2-service-account"
  description  = "Used for Composer 2 (managed Airflow)"
  disabled     = "false"
  display_name = "composer2-service-account"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--104228008692447712489" {
  account_id = "atn-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--104296524238941538670" {
  account_id = "clean-air-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--104433253766206552796" {
  account_id   = "github-actions-services-accoun"
  description  = "service account to handle GH actions"
  disabled     = "false"
  display_name = "github_actions_services_account"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--105781789064132478524" {
  account_id   = "cc-jarvus-airflow"
  description  = "Chris's service account for Airflow"
  disabled     = "false"
  display_name = "cc-jarvus-airflow"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--108192824187785555345" {
  account_id   = "jupyterlab"
  description  = "warehouse access for jupyterlab cloud"
  disabled     = "false"
  display_name = "jupyterlab"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--108511010517410478567" {
  account_id   = "backup-preprod"
  description  = "R/W access to preprod backups bucket"
  disabled     = "false"
  display_name = "backup-preprod"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--108990031826874583979" {
  account_id   = "metabase"
  description  = "Metabase  Bigquery access"
  disabled     = "false"
  display_name = "metabase"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--109486432003654134124" {
  account_id   = "cal-itp-reports-generation"
  description  = "For generation of calitp-reports website. Deprecate asap."
  disabled     = "false"
  display_name = "cal-itp-reports-generation"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--110811083403587775493" {
  account_id = "sbmtd-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--110962145619706212937" {
  account_id   = "backup-grafana"
  disabled     = "false"
  display_name = "backup-grafana"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--111041565629350650664" {
  account_id = "redwood-coast-transit"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--111080371999374643299" {
  account_id   = "gtfs-rt-archiver-test"
  description  = "Access to the gtfs-data-test bucket"
  disabled     = "false"
  display_name = "gtfs-rt-archiver-test"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--111148370496926482871" {
  account_id = "jyoung-cal-itp"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--111181631017890268696" {
  account_id = "test-natalyaa"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--111891315267954755979" {
  account_id = "lake-transit-authority"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--112089510539904302491" {
  account_id = "sacrt-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--113085154642268227475" {
  account_id = "mst-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--113224801129857519602" {
  account_id = "mendocino-transit-authority"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--113512472366715495471" {
  account_id   = "backup-metabase"
  description  = "R/W access to production metabase backups"
  disabled     = "false"
  display_name = "backup-metabase"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--114731815246487683241" {
  account_id   = "bq-transform-svcacct"
  description  = "Grants Airflow pod operators access to GCS and bigquery"
  disabled     = "false"
  display_name = "airflow-jobs-service-user"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--114755160399419974306" {
  account_id   = "metabase-payments-team"
  description  = "Service account for Payments Data Team to use via Metabase"
  disabled     = "false"
  display_name = "metabase-payments-team"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--115285307593924299795" {
  account_id   = "backups-test"
  disabled     = "false"
  display_name = "backups-test"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--115862066379506089980" {
  account_id   = "calitp-py-ci"
  description  = "CI testing for calitp-py library"
  disabled     = "false"
  display_name = "calitp-py-ci"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--116204646797454087621" {
  account_id   = "agency-hub-readonly"
  description  = "Read-only access for AgencyHub to read validation codes"
  disabled     = "false"
  display_name = "agency-hub-readonly"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--117250920371991618056" {
  account_id = "humboldt-transit-authority"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--117710413824821071161" {
  account_id   = "amplitude-export"
  disabled     = "false"
  display_name = "amplitude-export"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--117956330948086473326" {
  account_id   = "gtfs-rt-archiver"
  description  = "Service to upload GTFS-RT feeds to storage bucket"
  disabled     = "false"
  display_name = "gtfs-rt-archiver"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--118350215382382143206" {
  account_id   = "gh-actions-mobi-mart"
  description  = "Used to pull Provider Map data from warehouse into MobiMart site"
  disabled     = "false"
  display_name = "gh_actions_mobi_mart"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "github-actions-terraform" {
  account_id   = "github-actions-terraform"
  description  = "Service account for Github Actions to run Terraform"
  disabled     = "false"
  display_name = "github-actions-terraform"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "github-actions-service-account" {
  account_id   = "github-actions-service-account"
  description  = "Service account for general Github Actions tasks"
  disabled     = "false"
  display_name = "github-actions"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "composer-service-account" {
  account_id   = "composer-service-account"
  description  = "Service account for Composer"
  disabled     = "false"
  display_name = "composer"
  project      = "cal-itp-data-infra"
}

resource "google_service_account" "tfer--100119052859631924010" {
  account_id = "vctc-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}
