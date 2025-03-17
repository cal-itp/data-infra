resource "google_project" "tfer--cal-itp-data-infra" {
  auto_create_network = "true"
  billing_account     = "015228-460FCE-1AE928"
  folder_id           = "558493590469"
  name                = "cal-itp-data-infra"
  project_id          = "cal-itp-data-infra"
}
