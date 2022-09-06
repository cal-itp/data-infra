variable "env_name" {
  type        = string
  description = "target environment name"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*", var.env_name))
    error_message = "Invalid environment name (must match: '^[a-z][a-z0-9-]*')."
  }
}

variable "compute_region" {
  type        = string
  description = "default region for project compute deployments"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*", var.compute_region))
    error_message = "Invalid compute region (must match: '^[a-z][a-z0-9-]*')."
  }
}

variable "data_region" {
  type        = string
  description = "default region for project data storage"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*", var.data_region))
    error_message = "Invalid data region (must match: '^[a-z][a-z0-9-]*')."
  }
}
