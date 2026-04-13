# resource "google_bigquery_dataset" "erika_mart_ntd" {
#   dataset_id                      = "cal-itp-data-infra-staging.erika_mart_ntd"
#   description                     = "testing Metabase access"
#   location                        = "us-west2"

#   lifecycle {
#     prevent_destroy = true
#   }
# }


# resource "google_bigquery_dataset_iam_policy" "default" {
#   dataset_id  = google_bigquery_dataset.default.dataset_id
#   policy_data = data.google_iam_policy.default.policy_data
# }


# resource "google_bigquery_dataset_iam_member" "dataset_access" {
#   for_each   = toset(["mart_gtfs", "mart_gtfs_audit"])
#   dataset_id = each.value
#   role       = "roles/bigquery.dataViewer"
#   member     = "user:example@gmail.com"
# }
