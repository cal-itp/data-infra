env_name       = "prod"
compute_region = "us-west1"
data_region    = "us-west2"
service_accounts = [
  {
    name = "prod-service"
    role = "roles/editor"
  },
  {
    name = "prod-service2"
    role = "roles/editor"
  }
]
