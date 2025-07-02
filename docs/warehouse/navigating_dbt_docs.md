---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---

# Navigating the dbt Docs

`dbt` is the tool that we use to create data transformations in our warehouse, and it is also the tool that generates our dataset and table documentation.

Visit this link to view the [dbt Cal-ITP warehouse documentation](https://dbt-docs.dds.dot.ca.gov/#!/overview).

## How to use the documentation

In the [dbt Cal-ITP warehouse documentation](https://dbt-docs.dds.dot.ca.gov/#!/overview), you can navigate from either the `Database` perspective (table-level) or the `Project` perspective (as the files are configured in the repository).

### The `Database` Perspective

This allows you to view the dbt project as it exists in the warehouse.

To examine the documentation from the `Database` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.dds.dot.ca.gov/#!/overview), make sure that the `Database` tab is selected in the left-side panel
2. In the same left-side panel, under the `Tables and Views` heading, click on `cal-itp-data-infra` which will expand
3. Within that list, select the dataset schema of your choice
4. From here, a dropdown list of tables will appear and you can select a table to view its documentation

### The `Project` Perspective

This allows you to view the warehouse project as it exists as files in the repository.

To examine the documentation for our tables from the `Project` perspective:

- Once at the [dbt docs homepage](https://dbt-docs.dds.dot.ca.gov/#!/overview), make sure that the `Project` tab is selected in the left-side panel.
  - To examine our `source` tables:

    1. In the same left-side panel, find the `Sources` heading
    2. From here, select the source that you would like to view
    3. A dropdown list of tables will appear and you can select a table to view its documentation

  - To examine all of our other tables:

    1. In the same left-side panel, under the `Projects`, heading click on `calitp_warehouse` which will expand.
    2. Within that list, select `models`
    3. From here, file directories will appear below.
    4. Select the directory of your choice. A dropdown list of tables will appear and you can select a table to view its documentation
