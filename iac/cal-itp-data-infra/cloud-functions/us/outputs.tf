output "function_name" {
  value = google_cloudfunctions2_function.update_airtable.name
}

output "function_uri" {
  value = google_cloudfunctions2_function.update_airtable.service_config[0].uri
}
