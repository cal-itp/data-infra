# Cal-ITP's dbt project

This dbt project is intended to be the source of truth for the cal-itp-data-infra BigQuery warehouse.

## Setting up the project in your JupyterHub personal server
If you are developing dbt models in JupyterHub, the following pieces
are already configured/installed.
* Libraries such as gdal and graphviz
* The `gcloud` CLI
* `poetry`

> You may have already authenticated gcloud and the GitHub CLI (gh) if you followed the
[JupyterHub setup docs](https://docs.calitp.org/data-infra/analytics_tools/jupyterhub.html). If not, follow those instructions before proceeding.

### Clone and install the warehouse project
1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
   the `data-infra` repo via `git clone git@github.com:cal-itp/data-infra.git` if you haven't already. Use [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), not HTTPS. If you haven't made a folder/directory for your git repos yet, you can create one with `mkdir git` (within your home directory, usually).
   1. You may be prompted to accept GitHub key's fingerprint if you are cloning a repository for the first time.
2. The rest of these instructions assume you are in the `warehouse/` directory of the repository.
   1. You will need to `cd` to it via `cd <git-repos-path>/data-infra/warehouse/` or similar; for example, if you had created your directory with `mkdir git`, you will navigate to the warehouse directory with `cd git/data-infra/warehouse/`.
3. Execute `poetry install` to create a virtual environment and install requirements.
4. Execute `poetry run dbt deps` to install the dbt dependencies defined in `packages.yml` (such as `dbt_utils`).
5. Ensure that `DBT_PROFILES_DIR` is set to something like `~/.dbt/`; in JupyterHub, it should already be set to `/home/jovyan/.dbt/`. You can check with `echo $DBT_PROFILES_DIR`.
6. Execute `poetry run dbt init` to create the `$DBT_PROFILES_DIR` directory and a pre-built `profiles.yml` file; you will be prompted to enter a personal `schema` which is used as a prefix for your personal development environment schemas. The output should look similar to the following:
   ```
   ➜ poetry run dbt init
   19:14:32  Running with dbt=1.4.5
   19:14:32  Setting up your profile.
   schema (usually your name; will be added as a prefix to schemas e.g. <schema>_mart_gtfs): andrew
   maximum_bytes_billed (the maximum number of bytes allowed per BigQuery query; default is 100 GB) [100000000000]:
   19:14:35  Profile calitp_warehouse written to /Users/andrewvaccaro/.dbt/profiles.yml using project's profile_template.yml and your supplied values. Run 'dbt debug' to validate the connection.
   ```
   See [the dbt docs on profiles.yml](https://docs.getdbt.com/dbt-cli/configure-your-profile) for more background on this file.

   > Note: This default profile template will set a maximum bytes billed of 100 GB. You can override this during the init, or change it later by calling init again and choosing to overwrite (or editing the profiles.yml directly).
7. Check whether `~/.dbt/profiles.yml` was successfully created, e.g. `cat ~/.dbt/profiles.yml`. If you encountered an error, you may create it by hand and fill it with the same content:
   ```yaml
   calitp_warehouse:
     outputs:
       dev:
         fixed_retries: 1
         location: us-west2
         method: oauth
         priority: interactive
         project: cal-itp-data-infra-staging
         schema: <yourname>
         threads: 8
         timeout_seconds: 3000
         maximum_bytes_billed: 100000000000
         type: bigquery
         gcs_bucket: test-calitp-dbt-python-models
         dataproc_region: us-west2
         submission_method: serverless
         dataproc_batch:
           runtime_config:
             container_image: gcr.io/cal-itp-data-infra/dbt-spark:2023.3.28
             properties:
               spark.executor.cores: "4"
               spark.executor.instances: "4"
               spark.executor.memory: 4g
               spark.dynamicAllocation.maxExecutors: "16"
     target: dev
   ```
8. Finally, test your connection to our staging BigQuery project with `poetry run dbt debug`. You should see output similar to the following.
   ```
   ➜  warehouse git:(jupyterhub-dbt) ✗ poetry run dbt debug
   16:50:15  Running with dbt=1.4.5
   dbt version: 1.4.5
   python version: 3.9.16
   python path: /Users/andrewvaccaro/Library/Caches/pypoetry/virtualenvs/calitp-warehouse-YI2euBZD-py3.9/bin/python
   os info: macOS-12.3.1-x86_64-i386-64bit
   Using profiles.yml file at /Users/andrewvaccaro/.dbt/profiles.yml
   Using dbt_project.yml file at /Users/andrewvaccaro/go/src/github.com/cal-itp/data-infra/warehouse/dbt_project.yml

   Configuration:
     profiles.yml file [OK found and valid]
     dbt_project.yml file [OK found and valid]

   Required dependencies:
    - git [OK found]

   Connection:
     method: oauth
     database: cal-itp-data-infra-staging
     schema: andrew
     location: us-west2
     priority: interactive
     timeout_seconds: 3000
     maximum_bytes_billed: None
     execution_project: cal-itp-data-infra-staging
     job_retry_deadline_seconds: None
     job_retries: 1
     job_creation_timeout_seconds: None
     job_execution_timeout_seconds: 3000
     gcs_bucket: test-calitp-dbt-python-models
     Connection test: [OK connection ok]

   All checks passed!
   ```

## dbt Commands

Once you have performed the setup above, you are good to go run
[dbt commands](https://docs.getdbt.com/reference/dbt-commands) locally! Run the following commands in order.

1. `poetry run dbt seed`
   1. Will create tables in your personally-named schema from the CSV files present in [./seeds](./seeds), which can then be referenced by dbt models.
   2. You will need to re-run seeds if new seeds are added, or existing ones are changed.
2. `poetry run dbt run`
   1. Wll run all the models, i.e. execute SQL in the warehouse.
   2. In the future, you can specify [selections](https://docs.getdbt.com/reference/node-selection/syntax) to run only a subset of models, otherwise this will run *all* the tables).
   3. By default, your very first `run` is a [full refresh](https://docs.getdbt.com/reference/commands/run#refresh-incremental-models) but you'll need to pass the `--full-refresh` flag in the future if you want to change the schema of incremental tables, or "backfill" existing rows with new logic.

> In general, it's a good idea to run `seed` and `run --full-refresh` if you think your local environment is substantially outdated (for example, if you haven't worked on dbt models in a few weeks but want to create or modify a model). We have macros in the project that prevent a non-production "full refresh" from actually processing all possible data.

Some additional helpful commands:

* `poetry run dbt test` -- will test all the models (this executes SQL in the warehouse to check tables); for this to work, you first need to `dbt run` to generate all the tables to be tested
* `poetry run dbt compile` -- will compile all the models (generate SQL, with references resolved) but won't execute anything in the warehouse; useful for visualizing what dbt will actually execute
* `poetry run dbt docs generate` -- will generate the dbt documentation
* `poetry run dbt docs serve` -- will "serve" the dbt docs locally so you can access them via `http://localhost:8080`; note that you must `docs generate` before you can `docs serve`

### Incremental model considerations
We make heavy use of [incremental models](https://docs.getdbt.com/docs/build/incremental-models) in the Cal-ITP warehouse since we have large data volumes, but that data arrives in a relatively consistent pattern (i.e. temporal).

**In development**, there is a maximum lookback defined for incremental runs. The purpose of this is to handle situations where a developer may not have executed a model for a period of time. It's easy to handle full refreshes with a maximum lookback; we simply template in `N days ago` rather than the "true" start of the data for full refreshes. However, we also template in `MAX(N days ago, max DT of existing table)` for developer incremental runs; otherwise, going a month without executing a model would mean that a naive incremental implementation would then read in that full month of data. This means that your development environment can end up with gaps of data; if you've gone a month without executing a model, and then you execute a regular `run` that reads in the past `N` (7 currently) days of data, you will have a ~23 day gap. If this gap is unacceptable, you can resolve this in one of two ways.
* If you are able to develop and test with only recent data, execute a `--full-refresh` on your model(s) and all parents. This will drop the existing tables and re-build them with the last 7 days of data.
* If you need historical data for your analysis, copy the production table with `CREATE TABLE <your_schema>.<tablename> COPY <production_schema>.<tablename`; copies are free in BigQuery so this is substantially cheaper than fully building the model yourself.

## Setting up the project on your local machine

If you prefer to install dbt locally and use your own development environment, you may follow these instructions to install the same tools already installed in the JupyterHub environment.

> Note: These instructions assume you are on macOS, but are largely similar for
> other operating systems. Most *nix OSes will have a package manager that you
> should use instead of Homebrew.
>
> Note: if you get `Operation not permitted` when attempting to use the terminal,
> you may need to [fix your terminal permissions](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)
>
> You can enable [displaying hidden folders/files in macOS Finder](https://www.macworld.com/article/671158/how-to-show-hidden-files-on-a-mac.html)
   but generally, we recommend using the terminal when possible for editing
   these files. Generally, `nano ~/.dbt/profiles.yml` will be the easiest method
   for editing your personal profiles file. `nano` is a simple terminal-based
   text editor; you use the arrows keys to navigate and the hotkeys displayed
   at the bottom to save and exit. Reading an [online tutorial](https://www.howtogeek.com/howto/42980/the-beginners-guide-to-nano-the-linux-command-line-text-editor/)
   may be useful if you haven't used a terminal-based editor before.

### Install Homebrew (if you haven't)

1. Follow the installation instructions at [https://brew.sh/](https://brew.sh/)
2. Then, `brew install gdal graphviz` to install libraries used by some Python libraries.

### Install the Google SDK (if you haven't)

0. Implied: make sure that you have GCP permissions (i.e. that someone has added you to the GCP project)
1. Follow the installation instructions at [https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)
   1. If this is your first time using the terminal, we recommend reading [https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line](https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line)
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
2. You should also [set the application default](https://cloud.google.com/sdk/gcloud/reference/auth/application-default)
3. If `bq ls` shows output, you are good to go.

### Install poetry

1. Install [poetry](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions) (used for package/dependency management).
   1. If `curl -sSL https://install.python-poetry.org | python3 -`
      does not work, you can `curl` to a file `curl -sSL https://install.python-poetry.org -o install-poetry.py`
      and then execute the file with `python install-poetry.py`.
   2. Add the tool to your system PATH. This process varies by system, but the poetry installer provides a sample command for
      addition upon its completion. On an OSX device using zshell, for instance, that line should be added to the ~/.zshrc file.
2. Restart your terminal and confirm `poetry --version` works.
3. Ensure you have set the environment variable `DBT_PROFILES_DIR=~/.dbt/` in your `~/.zshrc`. You can either restart your terminal after setting it, or run `source ~/.zshrc`.
4. Follow the [warehouse setup instructions](#Set up the warehouse dbt project)
5. If this doesn’t work because of an error with Python version, you may need to install Python 3.9
   2. `brew install python@3.9`
   3. `brew link python@3.9`
   4. After restarting the terminal, confirm with `python3 --version` and retry `poetry install`


### Troubleshooting

#### Upgrading Poetry from legacy installer

If you installed Poetry using their legacy `get-poetry.py` script, you may run into issues upgrading to versions past [1.2.0](https://python-poetry.org/blog/announcing-poetry-1.2.0/). Here is a workflow that has worked:

1. Uninstall legacy installer: Run `rm -rf "${POETRY_HOME:-~/.poetry}"` (per [this Poetry docs page](https://python-poetry.org/docs/#installing-with-the-official-installer)).
2. Remove legacy path from shell profile: as noted above, shell configuration will vary by operating system and setup -- this may be `~/.zshrc` or similar. If you have a line like `export PATH="$HOME/.poetry/bin:$PATH"`, remove it.
3. Re-install Poetry via the new installer: `curl -sSL https://install.python-poetry.org | python3 -` (per their [1.2.0 upgrade docs](https://python-poetry.org/blog/announcing-poetry-1.2.0/))
4. Re-add new path to $PATH following the instructions that Poetry prints in the terminal upon installation.
5. Restart terminal.
6. Try running `poetry --version` to confirm installation has worked. If you get a warning about the location of your TOML configuration files, proceed to next step.
7. Double check what paths are listed in the warning message and run `mkdir <directory listed in "consider moving files to" section of warning> && mv <directory listed in "configuration exists at" section of warning>/config.toml ~/Library/Preferences/pypoetry/` to move the Poetry config TOML file from legacy location to new location. For example, this may be: `mkdir ~/Library/Preferences/pypoetry/ && mv ~/Library/Application\ Support/pypoetry/config.toml ~/Library/Preferences/pypoetry/`.
