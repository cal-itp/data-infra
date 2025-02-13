resource "google_kms_key_ring" "tfer--global_sops" {
  location = "global"
  name     = "sops"
  project  = "cal-itp-data-infra"
}
