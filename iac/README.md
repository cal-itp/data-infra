# Infrastructure as Code (IaC)

This subdirectory contains the Terraform configuration for Google Cloud.


## Local Development Setup

Install Terraform via ASDF:

```bash
$ asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
$ asdf install terraform 1.10.5
$ asdf global terraform 1.10.5
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

Run `terraform init` against each nested resource using `make plan`:

```bash
$ cd iac/
$ make init
```

To see any outstanding changes, run `terraform plan` recursively using `make plan`:

```bash
$ cd iac/
$ make plan
```
