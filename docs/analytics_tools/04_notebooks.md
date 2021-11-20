# Notebooks
(jupyterhub)=
## Introduction to JupyterHub
For Python users, we have deployed a cloud-based instance of JupyterHub to creating, using, and sharing notebooks easy.

This avoids the need to set up a local environment, provides dedicated storage, and allows you to push to GitHub.

**You can access JuypterHub [using this link](https://hubtest.k8s.calitp.jarv.us/)**.

## Using JupyterHub
Jupyterhub is a web application that allows users to analyze and create reports on warehouse data (or a number of data sources).

Analyses on jupyterhub are done using notebooks, which allow users to mix narrative with analysis code.

### Logging in to JupyterHub

JupyterHub currently lives at https://hubtest.k8s.calitp.jarv.us/hub/. In order to be added to the Cal-ITP JupyterHub, please [open an issue using this link](https://github.com/cal-itp/data-infra/issues/new?assignees=charlie-costanzo&labels=new+team+member&template=new-team-member.md&title=New+Team+Member+-+%5BName%5D).

### Connecting to the Warehouse

Connecting to the warehouse requires a bit of setup after logging in to JupyterHub.
Users need to download and install the gcloud commandline tool from the app.

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

See the screencast below for a full walkthrough.

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/6883b0bf9c8b4547a93d00bc6ba45b6d" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

### Uploading Data

Currently, report data can be stored in the `calitp-analytics-data` bucket.

In order to save data being used in a report, you can use two methods:

* Using code in your notebook to upload the data.
* Using the google cloud storage web UI to manually upload.

These are demonstrated in the screencast below.

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/51d22876ab6d4d35a39f18e8f6d5f11d" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

#### Uploading data from a notebook

The code below shows how to copy a file from JupyterHub to the data bucket.
Be sure to replace `<FILE NAME>` and `<ANALYSIS FOLDER>` with the appropriate names.

```python
# Using the `calitp` package
from calitp.storage import get_fs

fs = get_fs()

fs.put("<FILE NAME>", "gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")

# Using the `gcsfs` package
import gcsfs
import geopandas as gpd
import pandas as pd

# CSV
df = pd.read_csv("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")
df.to_csv("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")

# Parquet
df = pd.read_parquet("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")
df.to_parquet("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")

# Geoparquet
gdf = gpd.read_parquet("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")
gdf.to_parquet("gs://calitp-analytics-data/data-analyses/<ANALYSIS FOLDER>/<FILE NAME>")
```

#### Uploading from google cloud storage

You can access the cloud bucket from the web from https://console.cloud.google.com/storage/browser/calitp-analytics-data.

See the above screencast for a walkthrough of using the bucket.
