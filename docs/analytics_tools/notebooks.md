(jupyterhub)=
# Notebooks

## Introduction to JupyterHub
Jupyterhub is a web application that allows users to analyze and create reports on warehouse data (or a number of data sources).

Analyses on JupyterHub are accomplished using notebooks, which allow users to mix narrative with analysis code.

**You can access JuypterHub using this link:[notebooks.calitp.org](https://notebooks.calitp.org/)**.

## Table of Contents
1. [Using JupyterHub](#using-jupyterhub)
1. [Logging in to JupyterHub](#logging-in-to-jupyterhub)
1. [Connecting to the Warehouse](#connecting-to-the-warehouse)
1. [Increasing the Query Limit](#increasing-the-query-limit)
1. [Querying with SQL in JupyterHub](querying-sql-jupyterhub)
1. [Saving Code to Github](saving-code-jupyter)
1. [Environment Variables](#environment-variables)
1. [Jupyter Notebook Best Practices](notebook-shortcuts)

## Using JupyterHub
For Python users, we have deployed a cloud-based instance of JupyterHub to make creating, using, and sharing notebooks easy.

This avoids the need to set up a local environment, provides dedicated storage, and allows you to push to GitHub.

### Logging in to JupyterHub

JupyterHub currently lives at [notebooks.calitp.org](https://notebooks.calitp.org/).

Note: you will need to have been added to the Cal-ITP organization on GitHub to obtain access. If you have yet to be added to the organization and need to be, DM Charlie on Cal-ITP Slack <a href="https://cal-itp.slack.com/team/U027GAVHFST" target="_blank">using this link</a>.

(connecting-to-warehouse)=
### Connecting to the Warehouse

Connecting to the warehouse requires a bit of setup after logging in to JupyterHub, but allows users to query data in the warehouse directly.
To do this, you will need to download and install the gcloud commandline tool from the app.

See the screencast below for a full walkthrough.

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/6883b0bf9c8b4547a93d00bc6ba45b6d" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>


The commands required:
```python
# initial setup (in terminal) ----
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-361.0.0-linux-x86_64.tar.gz
tar -zxvf google-cloud-sdk-361.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
./google-cloud-sdk/bin/gcloud init

# log in to project ----
gcloud auth login
gcloud auth application-default login
```

### Increasing the Query Limit

By default, there is a query limit set within the Jupyter Notebook. Most queries should be within that limit, and running into `DatabaseError: 500 Query exceeded limit for bytes billed` should be a red flag to investigate whether such a large query is needed for the analysis. To increase the query limit, add and execute the following in your notebook:

```python
from calitp.tables import tbl

import os
os.environ["CALITP_BQ_MAX_BYTES"] = str(20_000_000_000)

tbl._init()
```

(querying-sql-jupyterhub)=
### Querying with SQL in JupyterHub

JupyterHub makes it easy to query SQL in the notebooks.

To query SQL, simply import the below at the top of your notebook:

```python
import calitp.magics
```
And add the following to the top of any cell block that you would like to query SQL in:

```sql
%%sql
```

Example:

```python
import calitp.magics
```
```sql
%%sql

SELECT
    COUNT(*)
FROM `views.gtfs_schedule_dim_feeds`
WHERE
    calitp_feed_name = "AC Transit (0)"
LIMIT 10
```
(saving-code-jupyter)=
### Saving Code to Github
Use [this link](committing-from-jupyterhub) to navigate to the `Saving Code` section of the docs to learn how to commit code to GitHub from the Jupyter terminal. Once there, you will need to complete the instructions in the following sections:
* [Adding a GitHub SSH Key to Jupyter](adding-ssh-to-jupyter)
* [Persisting your SSH Key and Enabling Extensions](persisting-ssh-and-extensions)
* [Cloning a Repository](cloning-a-repository)

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
* [Cheat Sheet - Jupyter Notebook ](https://defkey.com/jupyter-notebook-shortcuts?pdf=true&modifiedDate=20200909T053706)
* [Using Markdown in Jupyter Notebook](https://www.datacamp.com/community/tutorials/markdown-in-jupyter-notebook)
