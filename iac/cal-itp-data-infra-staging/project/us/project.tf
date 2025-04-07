resource "google_project" "tfer--cal-itp-data-infra-staging" {
  auto_create_network = "true"
  billing_account     = "015228-460FCE-1AE928"
  folder_id           = "1041649251888"
  name                = "cal-itp-data-infra-staging"
  project_id          = "cal-itp-data-infra-staging"
}
