# Cal-ITP's dbt project

This dbt project is intended to be the source of truth for the cal-itp-data-infra BigQuery warehouse.

## Setting up the project on your local machine

> Note: These instructions assume you are on macOS, but are largely similar for
> other operating systems. Most *nix OSes will have a package manager that you
> should use instead of Homebrew.
>
> Note: if you get `Operation not permitted` when attempting to use the terminal,
> you may need to [fix your terminal permissions](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)

### Install Homebrew (if you haven't)

1. Follow the installation instructions at [https://brew.sh/](https://brew.sh/)
2. Then, `brew install gdal` to install a geospatial library needed later

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

### Install poetry and Python/dbt dependencies

1. Install [poetry](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions) (used for package/dependency management).
   1. If `curl -sSL https://install.python-poetry.org | python3 -`
      does not work, you can `curl` to a file `curl -sSL https://install.python-poetry.org -o install-poetry.py`
      and then execute the file with `python install-poetry.py`.
   2. Add the tool to your system PATH. This process varies by system, but the poetry installer provides a sample command for
      addition upon its completion. On an OSX device using zshell, for instance, that line should be added to the ~/.zshrc file.
2. Restart your terminal and confirm `poetry --version` works.
3. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
   the `data-infra` repo if you haven't already. Use [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), not HTTPS. If you haven't made a folder/directory for your git repos yet, you can create one with `mkdir git` (within your home directory, usually).
4. Run `poetry install` to create a virtual environment and install requirements
   1. This needs to be run from within the `warehouse/` directory; you may need
      to `cd` to it via `cd <git-repos-path>/data-infra/warehouse/` or similar;
      for example, if you had created your directory with `mkdir git`, you will
      navigate to the warehouse directory with `cd git/data-infra/warehouse/`.
   2. If this doesn’t work because of an error with Python version, you may need to install Python 3.9
   3. `brew install python@3.9`
   4. `brew link python@3.9`
   5. After restarting the terminal, confirm with `python3 --version` and retry `poetry install`
5. `poetry run dbt deps` inside `warehouse/` to install the dbt dependencies defined in `packages.yml` (such as `dbt_utils`)

### Initialize your dbt profiles.yml

1. `poetry run dbt init` inside `warehouse/` will create a `.dbt/` directory in your home directory and a `.dbt/profiles.yml` file. By
   default it will also modify the existing profiles.yml within the repository - be sure not to commit your personal version of that
   file back to the repo. If given command prompts, follow them to set up your profiles.yml with the following values:

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

2. You can enable [displaying hidden folders/files in macOS Finder](https://www.macworld.com/article/671158/how-to-show-hidden-files-on-a-mac.html)
   but generally, we recommend using the terminal when possible for editing
   these files. Generally, `nano ~/.dbt/profiles.yml` will be the easiest method
   for editing your personal profiles file. `nano` is a simple terminal-based
   text editor; you use the arrows keys to navigate and the hotkeys displayed
   at the bottom to save and exit. Reading an [online tutorial](https://www.howtogeek.com/howto/42980/the-beginners-guide-to-nano-the-linux-command-line-text-editor/)
   may be useful if you haven't used a terminal-based editor before.
3. Check whether `~/.dbt/profiles.yml` was successfully created. If not, create it by hand and fill it with the same content:

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

4. See [the dbt docs on profiles.yml](https://docs.getdbt.com/dbt-cli/configure-your-profile) for more background on this file.

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
