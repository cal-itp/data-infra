env_name       = "local"
compute_region = "us-west1"
data_region    = "us-west1"
service_accounts = [
  {
    name = "jlott-service"
    role = "roles/editor"
  },
  {
    name = "jlott-service2"
    role = "roles/editor"
  }
]
