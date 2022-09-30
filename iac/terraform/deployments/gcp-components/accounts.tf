resource "google_service_account" "project_service_accounts" {
  count = length(var.service_accounts)
  display_name = var.service_accounts[count.index]["name"]
  account_id   = var.service_accounts[count.index]["name"]
}

resource "google_project_iam_member" "project_service_account_roles" {
  count = length(var.service_accounts)
  project = 1005246706141
  member  = "serviceAccount:${google_service_account.project_service_accounts[count.index].email}"
  role    = var.service_accounts[count.index]["role"]
}
