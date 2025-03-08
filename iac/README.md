# Infrastructure as Code (IaC)

This subdirectory contains the Terraform configuration for Google Cloud.


## Local Development Setup

Install Terraform via ASDF:

```bash
$ asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git
$ asdf install terraform 1.10.5
$ asdf set terraform 1.10.5
$ asdf reshim
```

Create the `iac/provider.tf` file containing the following provider definition:

```tf
terraform {
  required_providers {
    google = {
      version = "~> 4.59.0"
    }
  }
}
```

Initialize Terraform:

```bash
$ terraform init
```

Run `terraform init` against each nested resource using `make init`:

```bash
$ cd iac/
$ make init
```

To see any outstanding changes, run `terraform plan` recursively using `make plan`:

```bash
$ cd iac/
$ make plan
```


## Importing Resources

To install Terraformer:

```bash
$ asdf plugin add terraformer
$ asdf install terraformer 0.8.24
$ asdf set terraformer 0.8.24
$ asdf reshim
```

To import all GCS resources from staging:

```bash
$ terraformer import google --projects cal-itp-data-infra-staging -r 'gcs' --regions us
```

You'll need to move the imported resources to the correct directory:

```bash
$ mv generated/google/cal-itp-data-infra-staging/gcs cal-itp-data-infra-staging/gcs
```

Then, you'll need to run `terraform init` in the new directory. See below for a common error and resolution.

Once that completes, modify the `provider.tf` file to add the storage bucket:

```diff

  terraform {
    required_providers {
      google = {
        version = "~> 4.59.0"
      }
    }
+
+   backend "gcs" {
+     bucket = "calitp-staging-gcp-components-tfstate"
+     prefix = "cal-itp-data-infra-staging/gcs"
+   }
  }

```

Finally, run `terraform init` to upload the terraform state to GCS:

```bash
$ terraform init
Initializing the backend...
Acquiring state lock. This may take a few moments...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "gcs" backend. No existing state was found in the newly
  configured "gcs" backend. Do you want to copy this state to the new "gcs"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
```


## Common Errors

If you see this error while running `terraform init`:

```
Initializing the backend...
╷
│ Error: Invalid legacy provider address
│
│ This configuration or its associated state refers to the unqualified provider "google".
│
│ You must complete the Terraform 0.13 upgrade process before upgrading to later versions.
╵
```

You'll need to run:

```bash
$ terraform state replace-provider -- -/google hashicorp/google
```
