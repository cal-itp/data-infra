# Airflow

The following folder contains the project level directory for all our [Apache Airflow](https://airflow.apache.org/) [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html). Airflow is an orchestration tool that we use to manage our raw data ingest. Airflow DAG tasks are scheduled at regular intervals to perform data processing steps, like unzipping raw GTFS zipfiles and writing the contents out to Google Cloud Storage.


## Local Development

This project uses [composer-local-dev](https://github.com/GoogleCloudPlatform/composer-local-dev) to run DAGs locally.

In order to run most DAGs, you will need to follow a few setup steps.

### macOS / Linux

Login with `gcloud`:

```bash
$ gcloud auth application-default login --login-config=../iac/login.json
```

Install uv dependencies inside the warehouse and compile dbt:

```bash
$ cd ../warehouse
$ uv sync
$ uv run dbt deps
$ uv run dbt compile --target staging
```

Install dependencies for airflow:

```bash
$ cd ../airflow
$ uv sync
```

Setup composer environment:

```bash
$ make setup
```

Synchronize the environment files:

```bash
$ make sync
```

Start the reactor (this also runs `make setup` and `make sync`):

```bash
$ make start
```

After a loading period, the Airflow UI will become available at [`http://localhost:8080`](http://localhost:8080).

### Windows (git-bash)

#### Prerequisites

- [Git for Windows](https://git-scm.com/install/windows) -- installing with `winget` is recommended.
- [Rancher Desktop - Open a SNOW ticket to install](https://cdotprod.service-now.com/sp?id=sc_category) (provides Docker) — ensure it's running with `dockerd` (containerd mode may not work)
- [uv](https://docs.astral.sh/uv/getting-started/installation/#winget)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)

#### Tool Installation

Install `make` and `rsync` (not included in git-bash by default):

```bash
# Download and install make 4.4.1 from MSYS2
curl -sL "https://repo.msys2.org/msys/x86_64/make-4.4.1-2-x86_64.pkg.tar.zst" -o /tmp/make.pkg.tar.zst
# Extract and copy
python -c "import zstandard, tarfile, io; dctx=zstandard.ZstdDecompressor(); \
  open('/tmp/make.pkg.tar.zst','rb') as f, \
  dctx.stream_reader(f) as r, \
  tarfile.open(fileobj=r, mode='r|') as tar: tar.extractall(path='/tmp/msys2')"
cp /tmp/msys2/usr/bin/make.exe ~/bin/
cp /tmp/msys2/usr/share/locale ~/bin/ 2>/dev/null
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Download and install rsync 3.4.1 + xxhash DLL from MSYS2
curl -sL "https://repo.msys2.org/msys/x86_64/rsync-3.4.1-1-x86_64.pkg.tar.zst" -o /tmp/rsync.pkg.tar.zst
curl -sL "https://repo.msys2.org/msys/x86_64/libxxhash-0.8.2-1-x86_64.pkg.tar.zst" -o /tmp/xxhash.pkg.tar.zst
python -c "import zstandard, tarfile, io; dctx=zstandard.ZstdDecompressor(); \
  open('/tmp/rsync.pkg.tar.zst','rb') as f, \
  dctx.stream_reader(f) as r, \
  tarfile.open(fileobj=r, mode='r|') as tar: tar.extractall(path='/tmp/msys2')"
python -c "import zstandard, tarfile, io; dctx=zstandard.ZstdDecompressor(); \
  open('/tmp/xxhash.pkg.tar.zst','rb') as f, \
  dctx.stream_reader(f) as r, \
  tarfile.open(fileobj=r, mode='r|') as tar: tar.extractall(path='/tmp/msys2')"
cp /tmp/msys2/usr/bin/rsync.exe ~/bin/
cp /tmp/msys2/usr/bin/msys-xxhash-0.dll ~/bin/
source ~/.bashrc
```

If `make` or `rsync` do not run (exit code 127 / missing DLL), copy the required DLLs to a PATH directory or install via [MSYS2](https://www.msys2.org/) directly.

#### Environment Setup

Set the required environment variables in `~/.bashrc` (or run them in each git-bash session):

```bash
# make and rsync
export PATH="$HOME/bin:$PATH"
# unicode
export PYTHONIOENCODING=utf-8
```

Then source it:
```bash
$ source ~/.bashrc
```

### PodOperators

Airflow PodOperator tasks execute a specific Docker image; these images are pushed to [GitHub Container Registry](https://ghcr.io/) and production uses `:latest` tags while local uses `:development`. If you want to test these tasks locally, you must build and push development versions of the images used by the tasks, which requires [proper access](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).


### Common Issues

- If you want to clear out old local Airflow data, you'll need to delete the DAG using `uv tool run --from "composer-dev @ git+https://github.com/GoogleCloudPlatform/composer-local-dev.git@73ee40101970135a4e16d227d3738544bbc1f34e" composer-dev run-airflow-cmd calitp-development-composer dags delete <DAG_ID>` (the same command `COMPOSER_CMD` in the `Makefile` uses) where, for example, the `<DAG_ID>` is `create_external_tables`

- If you want to reset the Airflow database entirely, you'll need to delete the direcotry where the Postges container stores its data: `make clean-postgres`

- On macOS, if `composer-dev` complains it cannot connect to Docker, open Docker Desktop, `Settings > Advanced` and ensure that `Allow the default Docker socket to be used` is checked.

- Airflow exits with code 137 - Check that Docker has enough RAM (e.g. 8Gbs). See [this post](https://stackoverflow.com/questions/44533319/how-to-assign-more-memory-to-docker-container) on how to increase Docker resources.

- When testing a new or updated `requirements.txt`, you might not see packages update. You may need to run `make restart` to clear out old data.

- If a task does not start when expected, its designated [pool](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html) may not have been created locally. Pools can be created and managed in Airflow on a page accessed via the Admin -> Pools menu option. A DAG's designated pool can typically be found on its DAG Details page, and is generally defined in the `default_args` section of the DAG's `METADATA.yml` file.

- If a task is producing errors but not producing complete logs for troubleshooting, or if it's reporting a memory issue, you may need to increase the RAM given by default to the Docker virtual machine that Airflow runs on. In Docker Desktop this setting can be accessed via the Preferences -> Advanced menu, and requires a restart of the VM to take effect.


## Deployment

Airflow deployment is managed automatically by Terraform, automated by Github Actions. If you manually deploy Airflow, Terraform will delete the deployment the next time it applies a plan.

- The `dags/`, `plugins/`, and `../warehouse` directories are deployed automatically via terraform: to production from the `iac/cal-itp-data-infra/airflow` directory when a PR is merged into `main`, and to staging from the `iac/cal-itp-data-infra-staging/airflow` directory when `staging/official` changes. See [Staging Deployment](../docs/architecture/staging-deployment.md).
- System configuration for worker count, environment variables, `requirements-c3.txt`, and overrides of Airflow configs are deployed via terraform from the `iac/cal-itp-data-infra/composer` directory for production and the `iac/cal-itp-data-infra-staging/composer` directory for staging, following the same branches.
- Upgrades to Airflow/Composer versions are perfomed by editing the `config.software_config.image_version` value in `environment.tf`.
- The Docker containers used by `PodOperator` DAGs are built when a PR is merged into the `main` branch. More information can be found in the respective image READMEs.
- Environment variables for each environment are set via `.<environment>_c3.env` files (e.g., staging variables are in `.staging_c3.env`).


## Structure

The DAGs for this project are stored and version controlled in the `dags` folder. Each DAG has its own `README.md` with further information about its specific purpose and considerations.

Schedules are generally specified in cron format, and the Airflow scheduler uses the internal concept of a [data interval](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html#data-interval) to determine whether to kick off a DAG when scheduled. Some additional reading on the interaction between crontab values and Airflow's DAG start logic can be found in [this blog post](https://whigy.medium.com/why-my-scheduled-dag-does-not-run-9e2811b5030b).

When developing locally, logs for DAG runs are stored in the `logs/` directory. You should be unable to add files here, but the folder utilizes [a .gitkeep file](https://stackoverflow.com/a/7229996) so that it is consistently avaliable when testing and debugging.

Finally, Airflow plugins can be found in the `plugins/` directory; this includes general utility functions as well as custom [operator](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/operators.html) definitions.

### [gusty](https://github.com/pipeline-tools/gusty)

If a DAG contains a `METADATA.yml` file, it uses gusty. Each DAG folder contains a [`METADATA.yml` file](https://github.com/pipeline-tools/gusty#metadata) that contains overall DAG settings, including the DAG's schedule (if any).

### [cosmos](https://github.com/astronomer/astronomer-cosmos)

dbt dags are run using Cosmos, which turns a set of dbt models into a graph.


## Running automated tests

Each DAG for this project should have a corresponding test in the `tests/dags` folder. Tests are run from the command line and require a local installation of airflow to function.

1. `cp .env.example .env`
2. Fill in requested credentials
3. `uv run pytest`

Each test session runs against a fresh, temporary `AIRFLOW_HOME` and SQLite metadata database (see `tests/conftest.py`), so test runs don't read or write `~/airflow`.

The `[tool.uv] constraint-dependencies` in `pyproject.toml` pin every package to the version in the Composer image (`COMPOSER_VERSION` in the `Makefile`), overridden by `requirements-c3.txt`, so tests run against what production runs. After changing either, regenerate the constraints and the lockfile with `make composer-constraints` (requires Docker; pulls the image if it isn't local).


You can specify which tests you want to run by adding them after the `pytest` command.

To run all tests files from a specific path, add the path like this:

```bash
$ uv run pytest tests/scripts
```

To run a specific test file, add the file like this:

```bash
$ uv run pytest tests/scripts/test_gtfs_rt_parser.py
```

To run a specific test within a test file, you can add like this:

```bash
$ uv run pytest tests/scripts/test_gtfs_rt_parser.py::TestGtfsRtParser::test_no_vehicle_positions_for_date
```

We use [pytest-recording](https://github.com/kiwicom/pytest-recording) to record and replay HTTP traffic (the flow of data exchanged between a client and a web server).

To use VCR cassettes in your tests:

1. Add `@pytest.mark.vcr` before your test.

  ```
    @pytest.mark.vcr
    def test_execute():
  ```

2. Run `pytest` using `--record-mode=once`.

  ```bash
  $ uv run pytest tests/operators/test_airtable_to_gcs_operator.py::TestAirtableToGCSOperator --record-mode=once
  ```

If you need to rewrite VCR cassettes, use `--record-mode=rewrite`:

```bash
$ uv run pytest tests/scripts/test_gtfs_rt_parser.py::TestGtfsRtParser::test_no_vehicle_positions_for_date --record-mode=rewrite
```


## Testing Changes on Staging

Staging runs `main` plus the changes being tested on the `staging/official` branch. To test a change there before it reaches production:

  1. Open a PR from your branch into `staging/official` and get one approval.
  2. Once the `staging/guards` check passes, merge it (or enable auto-merge). If another test is using a file you change, the check waits until that test ends.
  3. Follow the deploy on [GitHub Actions](https://github.com/cal-itp/data-infra/actions), then test on [Airflow Staging](https://console.cloud.google/composer/environments/detail/us-west2/calitp-staging-composer).
  4. Promote it with your PR into `main`, which must match what was tested.

Branches named `staging/*` other than `staging/official` no longer deploy anything. See [Staging Deployment](../docs/architecture/staging-deployment.md) for updating, dropping and promoting tests, and for what the checks mean.


### Manually apply (break-glass only)

A local `terraform apply` deploys your checkout over whatever `staging/official` deployed, and the next deploy from `staging/official` overwrites it again. Use it only when the automation can't, and tell the team in `#data-infra`.

  1. Make your changes
  2. Login with google cloud `gcloud auth application-default login --login-config=../iac/login.json`
  3. Go to Terraform-Staging-Airflow path: `iac/cal-itp-data-infra-staging/airflow/us/`
  4. Run `terraform plan` to view the changes
  5. Run `terraform apply` to apply your changes
  6. Once it completes, you can test your changes on [Airflow Staging](https://console.cloud.google/composer/environments/detail/us-west2/calitp-staging-composer).


## Deploying Changes to Production

The [composer-apply-files](../.github/workflows/composer-apply-files.yml) GitHub Action runs when changes to this directory merge into `main`. It applies Terraform that updates the Composer environment from [requirements-c3.txt](./requirements-c3.txt) and [.production_c3.env](./.production_c3.env), and syncs the [DAGs](./dags) and [plugins](./plugins) directories to the bucket that Composer watches for code/data to parse. The same workflow deploys to staging when `staging/official` changes.


## Secrets

Airflow operators have dependencies on the following secrets, which are required to be set:

- `airflow-connections-airtable_default` is a password formatted according to Airflow connection conventions (e.g. `airflow://login:abc123@airflow`), see <https://cloud.google.com/composer/docs/composer-2/configure-secret-manager>
- `airflow-connections-http_blackcat`
- `airflow-connections-http_ckan`
- `airflow-connections-http_dot`
- `airflow-connections-http_kuba`
- `airflow-connections-http_mobility_database`
- `airflow-connections-http_ntd`
- `airflow-connections-http_transitland`

The following are provided by Littlepay to DDS:

- `LITTLEPAY_AWS_IAM_ANAHEIM_TRANSPORTATION_NETWORK_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_ATN_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_CAL_ITP_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_CALITP_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_CCJPA_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_CCJPA_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_HUMBOLDT_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_HUMBOLDT_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_LAKE_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_LAKE_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_MENDOCINO_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_MENDOCINO_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_NEVADA_COUNTY_CONNECTS_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_NEVADA_COUNTY_CONNECTS_ACCESS_KEY_V3`
- `LITTLEPAY_AWS_IAM_REDWOOD_COAST_TRANSIT_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_REDWOOD_COAST_TRANSIT_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_SACRT_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_SBMTD_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_SBMTD_ACCESS_KEY_FEED_V3`
