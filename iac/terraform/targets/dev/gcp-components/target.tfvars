env_name       = "dev"
compute_region = "us-west1"
data_region    = "us-west1"
service_accounts = [
  {
    name = "dev-service"
    role = "roles/editor"
  },
  {
    name = "dev-service2"
    role = "roles/editor"
  }
]
