variable "topic-name" {
  type        = string
  default     = "sentinel-topic"
  description = "Name of existing topic"
}

variable "organization-id" {
  type        = string
  default     = ""
  description = "Organization Identifier (optional)"
}

variable "tenant-id" {
  type        = string
  default     = "621b0a64-1740-43cc-8d88-4540d3487556"
  description = "Please enter your Sentinel tenant id"
}

locals {
  sentinel_app_id           = "2041288c-b303-4ca0-9076-9612db3beeb2" // Do not change it. It's our Azure Active Directory app id that will be used for authentication with your project.
  sentinel_auth_id          = "33e01921-4d64-4f8c-a055-5bdaffd5e33d" // Do not change it. It's our tenant id that will be used for authentication with your project.
  workload_identity_pool_id = replace(var.tenant-id, "-", "")        // Do not change it.
}
