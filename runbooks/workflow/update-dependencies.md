# Updating dependencies

How to bump a package across the monorepo. The pattern is the same: update the lock, pin the minimum in `pyproject.toml`, verify, test, commit.

Work one dependency at a time, test, and roll back if needed.

## Contents

- [Where dependencies live](#where-dependencies-live)
- [uv example: geopandas in warehouse](#uv-example-geopandas-in-warehouse)
- [Poetry example: requests in apps/maps](#poetry-example-requests-in-appsmaps)
- [requirements.txt: manual edit](#requirementstxt-manual-edit)
- [Run the tests](#run-the-tests)
- [Commit](#commit)
- [Rollback](#rollback)
- [Special cases](#special-cases)
  - [Pytest](#pytest)

## Where dependencies live

| Tool                                      | Subprojects                                                                                                                                                                                                                                                                                           |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| uv (`pyproject.toml` + `uv.lock`)         | `airflow`, `warehouse`, `images/jupyter-singleuser`, `services/gtfs-rt-archiver`, `runbooks/data/microbatch`, `airflow/composer/calitp-development-composer/data/warehouse`                                                                                                                           |
| Poetry (`pyproject.toml` + `poetry.lock`) | `packages/calitp-data-analysis`, `packages/calitp-data-infra`, `services/gtfs-rt-archiver-v3`, `apps/maps`, `ci`, `jobs/gtfs-schedule-validator`                                                                                                                                                      |
| `requirements.txt`                        | `airflow/requirements.txt`, `airflow/requirements-dev.txt`, `airflow/composer/calitp-development-composer/requirements.txt`, `services/gtfs-rt-archiver/requirements.txt`, `cloud-functions/update-expired-airtable-issues/requirements.txt`, `docs/requirements.txt`, `images/dask/requirements.txt` |
| npm                                       | `apps/maps`                                                                                                                                                                                                                                                                                           |

When bumping a package, search every `*.lock` and `requirements*.txt` to find every place it appears.

## uv example: geopandas in warehouse

```bash
( cd warehouse && uv lock --upgrade-package geopandas )
```

Pin the minimum in `warehouse/pyproject.toml`:

```diff
-    "geopandas>=1.0.0,<2",
+    "geopandas>=1.1.3,<2",
```

Verify the pin doesn't drift the lock:

```bash
( cd warehouse && uv lock )
git diff warehouse/uv.lock | grep -E '^[+-]version = '
```

Expect no output. Any line means a transitive package shifted version, which needs investigating before commit.

## Poetry example: requests in apps/maps

```bash
( cd apps/maps && poetry update requests --lock )
```

Pin the minimum in `apps/maps/pyproject.toml`:

```diff
-requests = "^2.24.0"
+requests = "^2.33.1"
```

Verify:

```bash
( cd apps/maps && poetry lock )
git diff apps/maps/poetry.lock | grep -E '^[+-]version = '
```

## requirements.txt: manual edit

Edit the pin directly:

```bash
urllib3==2.6.3 # NOTE: urllib3 is a big update
```

## Run the tests

Run the lines for whichever subprojects' lockfiles you touched:

```bash
# uv subprojects
( cd airflow && uv sync --locked --all-extras --dev && uv run pytest )
( cd warehouse && uv sync --locked --all-extras --dev && uv run dbt deps && uv run dbt parse && uv run dbt compile && uv run dbt run )
( cd services/gtfs-rt-archiver && uv sync --locked --all-extras --dev && uv run pytest )

# Poetry subprojects
( cd packages/calitp-data-analysis && poetry install && poetry run pytest )
( cd packages/calitp-data-infra && poetry install && poetry run pytest )
( cd services/gtfs-rt-archiver && poetry install && poetry run pytest )
( cd jobs/gtfs-schedule-validator && poetry install && poetry run pytest )

# apps/maps (Poetry + npm)
( cd apps/maps && poetry install && poetry run pytest )
```

## Commit

One commit per package:

```bash
git add <touched files>
git commit -m "chore(deps): bump <pkg> to <ver>"
```

Keep very large dependency updates (e.g., airflow, dbt) to one per PR. Multiple smaller dependencies or transitive dependencies can be bundled together if tests stay passing.

## Rollback

Pre-commit: `git checkout HEAD -- <touched files>`. Post-commit: `git revert <sha>`.

Common reasons a bump fails:

- A `pyproject.toml` upper bound is blocking the bump; lift the cap first, then re-lock.
- Co-required peer bump (e.g. `pyasn1` plus `pyasn1-modules`, `protobuf` plus `proto-plus`).
- Major-version breaking change that needs code edits.

## Special cases

- Major bumps (urllib3 1.x to 2.x, apache-airflow 2.x to 3.x, black 24.x to 26.x): own PR, expect code changes, run image builds.
- Re-locking a Poetry project on Poetry 2.x rewrites the lockfile from format 1.8.3 to 2.3.4 (extra `groups = [...]` entries, normalized constraint strings). No package versions move; commit it as part of the bump.

### Pytest

In some cases you may need to re-create pytext fixtures (such as for casettes that airflow uses) using the `--record-mode=rewrite` flag.

You should run the full pytest suite first and then check if any tests failed. Only re-record the failing test:

```sh
pytest tests/test_api.py::test_specific_endpoint --record-mode=rewrite
```

After re-recording the test fixture, add it to your commit and include it. If tests need bigger rewrites to pass, consider having the update be its own PR.
