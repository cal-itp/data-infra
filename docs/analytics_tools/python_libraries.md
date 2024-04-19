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

(python-libraries)=

# Useful Python Libraries

The following libraries are available and recommended for use by Cal-ITP data analysts. Our JupyterHub environment comes with all of these installed already, except for `calitp-data-infra`. A full list of the packages included in the system image that underpins our JupyterHub environment can be found (and updated when needed) [here](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml).

## Table of Contents

1. [shared utils](#shared-utils)
2. [calitp-data-analysis](#calitp-data-analysis)
3. [siuba](#siuba)
   <br> - [Basic Query](#basic-query)
   <br> - [Collect Query Results](#collect-query-results)
   <br> - [Show Query SQL](#show-query-sql)
   <br> - [More siuba Resources](#more-siuba-resources)
4. [pandas](#pandas-resources)
5. [Add New Packages](#add-new-packages)
6. [Updating calitp-data-analysis](#updating-calitp-data-analysis)
7. [Appendix: calitp-data-infra](#appendix)

(shared-utils)=

## shared utils

A set of shared utility functions can also be installed, similarly to any Python library. The `shared_utils` are stored in two places: [here](https://github.com/cal-itp/data-analyses/shared_utils) in `data-analyses`, which houses functions that are more likely to be updated. Shared functions that are updated less frequently are housed [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis/calitp_data_analysis) in the `calitp_data_analysis` package in `data-infra`. Generalized functions for analysis are added as collaborative work evolves so we aren't constantly reinventing the wheel.

### In terminal

- Navigate to the package folder: `cd data-analyses/_shared_utils`
- Use the make command to run through conda install and pip install: `make setup_env`
  - Note: you may need to select Kernel -> Restart Kernel from the top menu after make setup_env in order to successfully import shared_utils
- Alternative: add an `alias` to your `.bash_profile`:
  - In terminal use `cd` to navigate to the home directory (not a repository)
  - Type `nano .bash_profile` to open the .bash_profile in a text editor
  - Add a line at end: `alias go='cd ~/data-analyses/portfolio && pip install -r requirements.txt && cd ../_shared_utils && make setup_env && cd ..'`
  - Exit with Ctrl+X, hit yes, then hit enter at the filename prompt
  - Restart your server; you can check your changes with `cat .bash_profile`

### In notebook


See [data-analyses/starter_kit](https://github.com/cal-itp/data-analyses/tree/main/starter_kit) for examples on how to use `shared_utils` for general functions, charts, and maps.

(calitp-data-analysis)=

## calitp-data-analysis

`calitp-data-analysis` is an internal library of utility functions used to access our warehouse data for analysis purposes.

### import tbls

Most notably, you can include `import tbls` at the top of your notebook to import a table from the warehouse in the form of a `tbls`:

```python
from calitp_data_analysis.tables import tbls
```

Example:

```{code-cell}
from calitp_data_analysis.tables import tbls

tbls.mart_gtfs.dim_agency()
```

### query_sql

`query_sql` is another useful function to use inside of JupyterHub notebooks to turn a SQL query into a pandas DataFrame.

As an example, in a notebook:

```{code-cell}
from calitp_data_analysis.sql import query_sql
```

```{code-cell}
df_dim_agency = query_sql("""
SELECT
    *
FROM `mart_gtfs.dim_agency`
LIMIT 10""", as_df=True)
```

```{code-cell}
df_dim_agency.head()
```

(siuba)=

## siuba

`siuba` is a tool that allows the same analysis code to run on a pandas DataFrame,
as well as generate SQL for different databases.
It supports most [pandas Series methods](https://pandas.pydata.org/pandas-docs/stable/reference/series.html) analysts use. See the [siuba docs](https://siuba.readthedocs.io) for more information.

The examples below go through the basics of using siuba, collecting a database query to a local DataFrame,
and showing SQL test queries that siuba code generates.

(basic-query)=

### Basic query

```{code-cell}
from calitp_data_analysis.tables import tbls
from siuba import _, filter, count, collect, show_query

# query agency information, then filter for a single gtfs feed,
# and then count how often each feed key occurs
(tbls.mart_gtfs.dim_agency()
    >> filter(_.agency_id == 'BA', _.base64_url == 'aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L2RhdGFmZWVkcz9vcGVyYXRvcl9pZD1SRw==')
    >> count(_.feed_key)
)
```

(collect-query-results)=

### Collect query results

Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```{code-cell}
tbl_agency_names = tbls.mart_gtfs.dim_agency() >> collect()

# Use pandas .head() method to show first 5 rows of data
tbl_agency_names.head()

```

(show-query-sql)=

### Show query SQL

While `collect()` fetches query results, `show_query()` prints out the SQL code that siuba generates.

```{code-cell}
(tbls.mart_gtfs.dim_agency()
  >> filter(_.agency_name.str.contains("Metro"))
  >> show_query(simplify=True)
)

```

Note that here the pandas Series method `str.contains` corresponds to `regexp_contains` in Google BigQuery.

(more-siuba-resources)=

### More siuba Resources

- [siuba docs](https://siuba.readthedocs.io)
- ['Tidy Tuesday' live analyses with siuba](https://www.youtube.com/playlist?list=PLiQdjX20rXMHc43KqsdIowHI3ouFnP_Sf)

(pandas-resources)=

## pandas

The library pandas is very commonly used in data analysis, and the external resources below provide a brief overview of it's use.

- [Cheat Sheet - pandas](https://pandas.pydata.org/Pandas_Cheat_Sheet.pdf)

(add-new-packages)=

## Add New Packages

While most Python packages an analyst uses come in JupyterHub, there may be additional packages you'll want to use in your analysis.

- Install [shared utility functions](#shared-utils),
- Change directory into the project task's subfolder and add `requirements.txt` and/or `conda-requirements.txt`
- Run `pip install -r requirements.txt` and/or `conda install --yes -c conda-forge --file conda-requirements.txt`

(updating-calitp-data-analysis)=

## Updating calitp-data-analysis

`calitp-data-analysis` is a [package](https://pypi.org/project/calitp-data-analysis/) that lives [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis/calitp_data_analysis) in the `data-infra` repo. Follow the steps below update to the package.

<b>Steps </b>

Adapted from [this](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1694470040574809) and [this Slack thread](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1707252389227829).

1. Make the changes you want in the `calitp-data-analysis` folder inside `packages` [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis). If you are only changing package metadata (author information, package description, etc.) without changing the function of the package itself, that information lives in `pyproject.toml` rather than in the `calitp-data-analysis` subfolder.

   - If you are adding a new function that relies on a package that isn't already a dependency, run `poetry add <package name>` after changing directories to `data-infra/packages/calitp_data_analysis`. Check this [Jupyter image file](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml) for the version number associated with the package, because you should specify the version.
   - For example, your function relies on `dask`. In the Jupyter image file, the version is `dask = "~2022.8"` so run `poetry add dask==~2022.8` in the terminal.
   - You may also have run `poetry install mypy`. `mypy` is a package that audits Python files for information related to data types, and you can [read more about it here](https://mypy-lang.org/).
   - `mypy` is a package that audits Python files for information related to data types, and you can [read more about it here](https://mypy-lang.org/). `mypy` is one of the standard development dependencies for the `calitp-data-analysis package`, defined in the `pyproject.toml` file for the package, so to install it you can run `poetry install` in `packages/calitp-data-analysis/` (which will also install the other package dependencies). To use `mypy`, run `poetry run mypy [file or directory name you're interested in checking]`.
   - `mypy` is generally run in CI when a PR is opened, as part of build tasks. You can see it called [here](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/build-calitp-data-analysis.yml#L40) for this package in `build-calitp-data-analysis.yml`. Within the PR, the "Test, visualize, and build calitp-data-analysis" CI workflow will fail if problems are found.
   - More helpful hints for [passing mypy in our repo](https://github.com/cal-itp/data-infra/blob/main/README.md#mypy).

2. Each time you update the package, you must also update the version number. We use dates to reflect which version we are on. Update the version in [pyproject.toml](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-analysis/pyproject.toml#L3) that lives in `calitp-data-analysis` to either today's date or a future date.

3. Open a new pull request and make sure the new version date appears on the [test version page](https://test.pypi.org/project/calitp-data-analysis/).

   - The new version date may not show up on the test page due to errors. Check the GitHub Action page of your pull request to see the errors that have occurred.
   - If you run into the error message like this, `error: Skipping analyzing "dask_geopandas": module is installed, but missing library stubs or py.typed marker  [import]` go to your `.py` file and add `# type: ignore` behind the package import.
   - To fix the error above, change `import dask_geopandas as dg` to `import dask_geopandas as dg  # type: ignore`.
   - It is encouraged to make changes in a set of smaller commits. For example, add all the necessary packages with `poetry run <package` first, fix any issues flagged by `mypy`, and finally address any additional issues.

4. Merge the PR. Once it is merged in, the [actual package](https://pypi.org/project/calitp-data-analysis/) will display the new version number. To make sure everything works as expected, run `pip install calitp-data-analysis==<new version here>` in a cell of Jupyter notebook and import a package (or two) such as `from calitp_data_analysis import styleguide`.

5. Update the new version number in the `data-infra` repository [here](https://github.com/cal-itp/data-infra/blob/main/images/dask/requirements.txt#L30), [here](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml#L48), [here](https://github.com/cal-itp/data-infra/blob/main/docs/requirements.txt), and anywhere else you find a reference to the old version of the package. You'll also want to do the same for any other Cal-ITP repositories that reference the `calitp-data-analysis` package.

   - When yu update the [jupyter-singleuser toml](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml#L48), make sure to run `poetry add calitp-data-analysis==<new version here>` and commit the updated `poetry.lock` file.
   - As of writing, the only other repository that references to the package version is [reports](https://github.com/cal-itp/reports).

<b>Resources</b>

- [Issue #870](https://github.com/cal-itp/data-analyses/issues/870)
- [Pull Request #2994](https://github.com/cal-itp/data-infra/pull/2944)
- [Slack thread](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1694470040574809)

(appendix)=

## Appendix: calitp-data-infra

The [calitp-data-infra](https://pypi.org/project/calitp-data-infra/) package, used primarily by warehouse mainainers and data pipeline developers, includes utilities that analysts will likely not need need to interact with directly (and therefore generally won't need to install), but which may be helpful to be aware of. For instance, the `get_secret_by_name()` and `get_secrets_by_label()` functions in [the package's `auth` module](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/auth.py) are used to interact with Google's [Secret Manager](https://console.cloud.google.com/security/secret-manager), the service that securely stores API keys and other sensitive information that underpins many of our data syncs.

You can read more about the `calitp-data-infra` Python package [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-infra#readme).
