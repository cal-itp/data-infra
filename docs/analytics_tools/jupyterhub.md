(jupyterhub-intro)=

# JupyterHub

## Introduction to JupyterHub

Jupyterhub is a web application that allows users to analyze and create reports on warehouse data (or a number of data sources).

Analyses on JupyterHub are accomplished using notebooks, which allow users to mix narrative with analysis code.

**You can access JuypterHub using this link: [notebooks.calitp.org](https://notebooks.calitp.org/)**.

## Table of Contents

1. [Using JupyterHub](#using-jupyterhub)
2. [Logging in to JupyterHub](#logging-in-to-jupyterhub)
3. [Connecting to the Warehouse](#connecting-to-the-warehouse)
4. [Increasing the Query Limit](#increasing-the-query-limit)
5. [Increase the User Storage Limit](#increasing-the-storage-limit)
6. [Querying with SQL in JupyterHub](querying-sql-jupyterhub)
7. [Saving Code to Github](saving-code-jupyter)
8. [Environment Variables](#environment-variables)
9. [Jupyter Notebook Best Practices](notebook-shortcuts)
10. [Developing warehouse models in Jupyter](jupyterhub-warehouse)

## Using JupyterHub

For Python users, we have deployed a cloud-based instance of JupyterHub to make creating, using, and sharing notebooks easy.

This avoids the need to set up a local environment, provides dedicated storage, and allows you to push to GitHub.

### Logging in to JupyterHub

JupyterHub currently lives at [notebooks.calitp.org](https://notebooks.calitp.org/).

Note: you will need to have been added to the Cal-ITP organization on GitHub to obtain access. If you have yet to be added to the organization and need to be, ask in the `#services-team` channel in Slack.

(connecting-to-warehouse)=

### Connecting to the Warehouse

Connecting to the warehouse requires a bit of setup after logging in to JupyterHub, but allows users to query data in the warehouse directly.
To do this, you will need to download and install the gcloud commandline tool from the app.

See the screencast below for a full walkthrough.

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/6883b0bf9c8b4547a93d00bc6ba45b6d" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

The commands required:

```bash
# init will both authenticate and do basic configuration
# You do not have to set a default compute region/zone
gcloud init

# Optionally, you can auth and set the project separately
gcloud auth login
gcloud config set project cal-itp-data-infra

# Regardless, set up application default credentials
gcloud auth application-default login
```

If you are still not able to connect, make sure you have the suite of permissions associated with other analysts.

### Increasing the Query Limit

By default, there is a query limit set within the Jupyter Notebook. Most queries should be within that limit, and running into `DatabaseError: 500 Query exceeded limit for bytes billed` should be a red flag to investigate whether such a large query is needed for the analysis. To increase the query limit, add and execute the following in your notebook:

```python
from calitp_data_analysis.tables import tbls

import os
os.environ["CALITP_BQ_MAX_BYTES"] = str(20_000_000_000)

tbls._init()
```

(querying-sql-jupyterhub)=

### Increasing the Storage Limit

By default, new JupyterHub instances are subject to a 10GB storage limit. This setting comes from the underlying infrastructure configuration, and requires some interaction with Kubernetes Engine in Google Cloud to modify.

If a JupyterHub user experienced an error indicating `no space left on device` or similar, their provisioned storage likely needs to be increased. This can be done from within the Storage section of [the Google Kubernetes Engine web UI](https://console.cloud.google.com/kubernetes/list/overview?project=cal-itp-data-infra). Click into the "claim-[username]" entry associated with the user (*not* the "pvc-[abc123]" persistent volume associated with that entry), navigate to the "YAML" tab, and change the storage resource request under `spec` and the storage capacity limit under `status`.

After making the configuration change in GKE, shut down and restart the user's JupyterHub instance. If the first restart attempt times out, try again once or twice - it can take a moment for the scaleup to complete and properly link the storage volume to the JupyterHub instance.

100GB should generally be more than enough for a given user - if somebody's storage has already been set to 100GB and they hit a space limit again, that may indicate a need to clean up past work rather than a need to increase available storage.

### Querying with SQL in JupyterHub

JupyterHub makes it easy to query SQL in the notebooks.

To query SQL, simply import the below at the top of your notebook:

```python
import calitp_data_analysis.magics
```

And add the following to the top of any cell block that you would like to query SQL in:

```sql
%%sql
```

Example:

```python
import calitp_data_analysis.magics
```

```sql
%%sql

SELECT
    COUNT(*)
FROM `mart_gtfs.dim_schedule_feeds`
WHERE
    key = "db58891de4281f965b4e7745675415ab"
LIMIT 10
```

(saving-code-jupyter)=

### Saving Code to Github

Use [this link](committing-from-jupyterhub) to navigate to the `Saving Code` section of the docs to learn how to commit code to GitHub from the Jupyter terminal. Once there, you will need to complete the instructions in the following sections:

- [Adding a GitHub SSH Key to Jupyter](authenticating-github-jupyter)
- [Persisting your SSH Key and Enabling Extensions](persisting-ssh-and-extensions)
- [Cloning a Repository](cloning-a-repository)

### Environment Variables

Sometimes if data access is expensive, or if there is sensitive data, then accessing it will require some sort of credentials (which may take the form of passwords or tokens).

There is a fundamental tension between data access restrictions and analysis reproducibility. If credentials are required, then an analysis is not reproducible out-of-the-box. However, including these credentials in scripts and notebooks is a security risk.

Most projects should store the authentication credentials in environment variables, which can then be read by scripts and notebooks. The environment variables that are required for an analysis to work should be clearly documented.

Analysts should store their credentials in a `_env` file, a slight variation of the typical `.env` file, since the `.env` won't show up in the JupyterHub filesystem.

Some credentials that need to be stored within the `_env` file may include GitHub API key, Census API key, Airtable API key, etc. Store them in this format:

```python
GITHUB_API_KEY=ABCDEFG123456789
CENSUS_API_KEY=ABCDEFG123456789
AIRTABLE_API_KEY=ABCDEFG123456789
```

To pass these credentials in a Jupyter Notebook:

```python
import dotenv
import os

# Load the env file
dotenv.load_dotenv("_env")

# Import the credential (without exposing the password!)
GITHUB_API_KEY = os.environ["GITHUB_API_KEY"]
```

(notebook-shortcuts)=

### Jupyter Notebook Best Practices

External resources:

- [Cheat Sheet - Jupyter Notebook](https://defkey.com/jupyter-notebook-shortcuts?pdf=true&modifiedDate=20200909T053706)
- [Using Markdown in Jupyter Notebook](https://www.datacamp.com/community/tutorials/markdown-in-jupyter-notebook)

(jupyterhub-warehouse)=

### Developing warehouse models in JupyterHub

See the [warehouse README](https://github.com/cal-itp/data-infra/tree/main/warehouse#readme) for warehouse project setup instructions.
