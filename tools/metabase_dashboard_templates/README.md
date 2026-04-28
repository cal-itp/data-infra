# Metabase Dashboard Templates

This document defines two related scripts for working with Metabase dashboards:

- `dashboard-to-template`: A script that takes a dashboard ID and creates a YAML template file from it.
- `template-to-dashboard`: A script that takes a YAML template file and creates or updates a dashboard in Metabase.

A dashboard template file is a Jinja-templated YAML file that contains the structure of a dashboard, but with placeholders for things like table and field IDs. The template file can be used to create or update dashboards in different Metabase instances or with different database connections.

The data in the YAML file is intended to be human-readable and editable, and should be usable with the [Metabase API](https://www.metabase.com/docs/latest/api).

## Motivation

Creating and maintaining payments dashboards for each transit agency is currently a manual process that involves a lot of manual updates to dashboards via the Metabase UI. This process is error-prone and time-consuming, especially when we need to make updates to the dashboard structure or add new metrics.

### The current process

The current process for creating a new payments dashboard for an agency looks something like this:

1. Create a service account with the necessary permissions (manual)
2. Create a Metabase DB connection using the service account credentials (manual)
3. Create a new collection in Metabase for the agency (manual)
4. Recreate the payments dashboard in the new collection using the new database connection (manual, time-consuming, and error-prone)

To add a new metric to all payments dashboards, we need to perform step 4 above for each agency, which involves manually editing each dashboard in the Metabase UI.

### Proposal 1: Python script to create/update dashboards from a template file

The first proposal is to create a series of Python scripts that can automate the process of abstracting a dashboard into a template file and then creating/updating dashboards from that template file. This would allow us to maintain a single source of truth copy of the target dashboard which can be updated via the Metabase UI, exported as a template file, and then used to create/update dashboards in different Metabase collections.

The process for creating/updating a dashboard from a template dashboard would look something like this:

1. Create a service account with the necessary permissions (manual)
2. Create a Metabase DB connection using the service account credentials (manual)
3. If there's not a template file yet, create a template file from an existing dashboard using the `dashboard-to-template` script (manual, but only needs to be done once per dashboard, and is very quick)
4. Use the `template-to-dashboard` script to create the dashboard in the new Metabase collection

To add a new metric to all payments dashboards, we would just need to update the template dashboard, export a new template file, and then run the `template-to-dashboard` script for each agency to update their dashboards.

To test:

1. Download existing payments dashboard from production as a template file
2. Create a new collection in staging Metabase
3. Create a new database connection in staging Metabase
4. Use the `template-to-dashboard` script to create a new dashboard in the new collection in staging Metabase using the template file and the new database connection

The advantages of this approach are:

- Analysts can have full control over the process, as there wouldn't be any changes to terraform files or other infrastructure as code. The scripts would just interact with the Metabase API to create/update dashboards.

The disadvantages of this approach are:

- It would require analysts to run the scripts manually, which could lead to inconsistencies if not done correctly. However, this could be mitigated with good documentation and training.
- The template files would not need to be stored in version control, which could lead to issues with tracking changes to the dashboard structure over time. But again, this could be mitigated with good documentation and training around how to use the scripts and manage the template files.

Open questions include:

- Should the scripts' behavior be folded into one of the analysts' packages (e.g. `calitp-data-infra`) so that analysts could call the functions from, e.g., a Jupyter notebook?

### Proposal 2: Terraform null_resource to create/update dashboards from a template file

The second proposal is to create a Terraform `null_resource` that can create/update dashboards from a template file. This is not necessarily mutually exclusive with the first proposal, as the `null_resource` would likely still call the same scripts. However, it would require more setup and maintenance, and would likely be less flexible than the Python script approach. For example, we would likely need to maintain a list of agencies that have dashboards created for them in the Terraform local variable. This could be seen as a good thing too.

The process for creating/updating a dashboard from a template dashboard using Terraform would look something like this:

1. Create a service account with the necessary permissions (manual)
2. Create a Metabase DB connection using the service account credentials (manual)
3. If there's not a template file yet, create a template file from an existing dashboard using the `dashboard-to-template` script (manual, but only needs to be done once per dashboard, and is very quick)
4. Update the Terraform local variable that lists the agencies with dashboards to include the new agency, and then run `terraform apply` to create the dashboard in the new Metabase collection

The advantages of this approach are:

- The process would be more automated and tied to our existing CI/CD practices, which could lead to more consistency in how dashboards are created and updated.
- As we move more Metabase configuration (such as the database connections and collections) into Terraform, we would be able to automatically inject the necessary information (e.g. database connection ID) into the template context for creating/updating dashboards, which would reduce the chances of human error in running the scripts.

The disadvantages of this approach are:

- We would need to make it clear that Terraform is the source of truth for certain dashboards, and manual changes to those dashboards in the Metabase UI would be overwritten by Terraform.

## General Script Requirements

### Creating a Dashboard Template File from a Dashboard

![Diagram of the process of creating a dashboard template file from a dashboard](./Metabase%20Dashboard%20Templates%20-%20Create%20Template%20File.png)

Calling the command might be something like this:

```bash
python3 tools/metabase_dashboard_templates/cli.py \
  --metabase-url http://localhost:3000 \
  --metabase-api-key abc123 \
  dashboard-to-template \
  --dashboard-id 123 \
  --template-file dashboard_template.json
```

The script will need to interact with the Metabase API to retrieve [database metadata](https://www.metabase.com/docs/latest/api#tag/apidatabase/get/api/database/{id}/metadata) in order to replace table and field IDs with their names in the template file.

### Creating/Updating a Dashboard from a Template File

![Diagram of the process of creating/updating a dashboard from a template file](./Metabase%20Dashboard%20Templates%20-%20Create%20Dashboard.png)

The signatures for the Jinja template functions could be something like:

```python
def get_table_id(database_id: int, table_name: str) -> int:
    """
    Returns the ID of the table with the given name in the
    database connection with the given ID.
    """
    pass

def get_field_id(database_id: int, table_name: str, field_name: str) -> int:
    """
    Returns the ID of the field with the given name in the
    table with the given name in the database connection
    with the given ID.
    """
    pass
```

The template context should also provide `collection_id` (the target
collection for the dashboard and its cards).

Calling the command might be something like this:

```bash
python3 tools/metabase_dashboard_templates/cli.py \
  --metabase-url http://localhost:3000 \
  --metabase-api-key abc123 \
  template-to-dashboard \
  --template-file dashboard_template.json \
  --template-context '{
    "database_id": 1,
    "collection_id": 22
  }'
```
