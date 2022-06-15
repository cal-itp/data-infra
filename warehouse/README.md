# Cal-ITP's dbt project

This dbt project is intended to be the source of truth for the cal-itp-data-infra BigQuery warehouse.

##  Setting up the project on your local machine

> Note: These instructions assume you are on macOS, but are largely similar for
> other operating systems. Most *nix OSes will have a package manager that you
> should use instead of Homebrew.

> Note: if you get `Operation not permitted` when attempting to use the terminal,
> you may need to [fix your terminal permissions](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)

### Install Homebrew (if you haven't)
1. Follow the installation instructions at https://brew.sh/
2. Then, `brew install gdal` to install a geospatial library needed later

### Install the Google SDK (if you haven't)
0. Implied: make sure that you have GCP permissions (i.e. that someone has added you to the GCP project)
1. Follow the installation instructions at https://cloud.google.com/sdk/docs/install
   1. If this is your first time using the terminal, we recommend reading https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line
      or another tutorial first. You will generally need to understand `cd` and
      the concept of the "home directory" aka `~`. When you first open the
      terminal, your "working directory" will be the home directory. Running the
      `cd` command without any arguments will set your working directory back to
      `~`.
   2. Use `tar -xvf <drag file from Finder window to get file name> ~` to unzip into your home directory
   3. Answer `yes` to adding the tool to your path
   4. Most recent macOS versions use `zsh` as the default shell, so ensure the path modification is added to `~/.zshrc` when prompted
   5. Restart your terminal, and run `gcloud init`
   6. Answer `yes` to log in, and select the Google account associated with GCP
   7. Set `cal-itp-data-infra` as the default project, and do not set a region
3. You should also [set the application default](https://cloud.google.com/sdk/gcloud/reference/auth/application-default)
4. If `bq ls` shows output, you are good to go.


### Install poetry and Python/dbt dependencies
1. Install [poetry](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions) (used for package/dependency management).
   1. If `curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -`
      does not work, you can `curl` to a file `curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py`
      and then execute the file with `python get-poetry.py`.
   2. Answer `yes` to adding the tool to your path
2. Restart your terminal and confirm `poetry --version` works.
3. `poetry install` to create a virtual environment and install requirements
   1. Now would be the time to [clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
      the `data-infra` repo if you haven't already. Use [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account),
      not HTTPS.
   2. This needs to be run from within the `warehouse/` directory; you may need
      to `cd` to it via `cd <git-repos-path>/data-infra/warehouse/` or similar.
   3. If this doesn’t work because of an error with Python version, you may need to install Python 3.9
   4. `brew install python@3.9`
   5. `brew link python@3.9`
   6. After restarting the terminal, confirm with `python3 --version` and retry `poetry install`
4. `poetry run dbt deps` to install the dbt dependencies defined in `packages.yml` (such as `dbt_utils`)

### Initialize your dbt profiles.yml
1. `poetry run dbt init` inside `warehouse/` will create a `.dbt/` directory in your home directory and a `.dbt/profiles.yml` file.
2. Fill out your `~/.dbt/profiles.yml` with the following content.
```yaml
calitp_warehouse:
  target: dev
  outputs:
    dev:
      schema: <enter your first name or initials here, like "laurie" or "lam">
      fixed_retries: 1
      location: us-west2
      method: oauth
      priority: interactive
      project: cal-itp-data-infra-staging
      threads: 4
      timeout_seconds: 300
      type: bigquery
```
3. See [the dbt docs on profiles.yml](https://docs.getdbt.com/dbt-cli/configure-your-profile) for more background on this file.

## Running the project locally

Once you have performed the setup above, you are good to go run
[dbt commands](https://docs.getdbt.com/reference/dbt-commands) locally!

Some especially helpful commands:
* `poetry run dbt compile` -- will compile all the models (generate SQL, with references resolved) but won't execute anything in the warehouse
* `poetry run dbt run` -- will run all the models -- this will execute SQL in the warehouse (specify [selections](https://docs.getdbt.com/reference/node-selection/syntax) to run only a subset of models, otherwise this will run *all* the tables)
* `poetry run dbt test` -- will test all the models (this executes SQL in the warehouse to check tables); for this to work, you first need to `dbt run` to generate all the tables to be tested
* `poetry run dbt docs generate` -- will generate the dbt documentation
* `poetry run dbt docs serve` -- will "serve" the dbt docs locally so you can access them via `http://localhost:8080`; note that you must `docs generate` before you can `docs serve`

TODO: project standards and organization
