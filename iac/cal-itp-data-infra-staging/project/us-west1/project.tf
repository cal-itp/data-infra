resource "google_project" "tfer--cal-itp-data-infra-staging" {
  auto_create_network = "true"
  billing_account     = "01BF29-618B79-F45E82"
  deletion_policy     = "PREVENT"
  folder_id           = "1041649251888"
  name                = "cal-itp-data-infra-staging"
  project_id          = "cal-itp-data-infra-staging"
}
