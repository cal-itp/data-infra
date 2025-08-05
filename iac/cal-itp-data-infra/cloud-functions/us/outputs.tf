output "update_expired_airtable_issues_name" {
  value = google_cloudfunctions2_function.update_expired_airtable_issues.name
}

output "update_expired_airtable_issues_uri" {
  value = google_cloudfunctions2_function.update_expired_airtable_issues.service_config[0].uri
}
