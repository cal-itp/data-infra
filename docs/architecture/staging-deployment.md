# Staging Deployment

This page explains how code reaches the staging environment (`cal-itp-data-infra-staging`), how to test a change there before it goes to production, and what the automation around it does. The design is tracked in [#5803](https://github.com/cal-itp/data-infra/issues/5803).

## The model

- **Infrastructure (`iac/**`) goes through `main`.** Terraform changes to either project are production changes. Staging infrastructure modules apply when their PR merges into `main`, just like production ones.
- **Code deploys to staging only from the `staging/official` branch**, and to production only from `main`. "Code" means Airflow DAGs and plugins, Composer packages and environment variables, dbt (model runs, docs, artifacts, Metabase sync) and the GTFS-RT archiver.
- **`staging/official` always exists, and equals `main` plus the tests currently running.** After every merge into `main`, a sync merges `main` into `staging/official`. With no tests running, staging runs exactly what production runs.
- **A test** is one feature branch's changes merged into `staging/official` through one or more PRs. A test **holds** the files it changed for as long as they differ between `staging/official` and `main`.
- **Testing in staging is optional.** A PR can go straight to `main`. It only has to wait if it changes a file that a running test holds.

Other `staging/*` branches no longer deploy anything.

## Testing a change

👤 = you, ⚙️ = automated.

### Start a test

1. 👤 Open a PR from your branch (say `feature/x`) into `staging/official`. You can open the PR into `main` now or later. If it already exists, you can add `Promotes via: #NNNN` (its number) to the staging PR's description; this is optional and only used to link the two on the [status issue](#status-and-alerts).
2. ⚙️ The `staging/guards` check runs (see [Checks](#checks)). If your PR changes a file another test holds, the check shows **pending: Waiting on staging test #N** rather than failing.
3. 👤 Get one approval, then merge, or turn on **auto-merge** so it merges itself once the check passes.
4. ⚙️ The merge deploys whatever your PR touches to staging.
5. 👤 Verify in staging. If you changed `airflow/requirements-c3.txt`, also check that the **Staging Composer** job of the *Apply Terraform for Warehouse and DAG changes* workflow succeeded: a Composer update takes tens of minutes and can fail on a package conflict while the DAGs still upload.

### Update a test

👤 Push to `feature/x` and open another PR from it into `staging/official`. If the feature changes after its last staging merge (for example, after review feedback), you must do this before promoting, or the `staging/gate` check on your PR into `main` fails.

### Promote

1. 👤 Open (or mark ready) the PR from `feature/x` into `main` and get it reviewed as usual.
2. ⚙️ `staging/gate` requires **every file the PR changes to match `staging/official`**, so production gets exactly what was tested and nothing more.
3. 👤 Merge. ⚙️ Production deploys, the sync brings the change into `staging/official`, the test's files now match `main`, and they're released. PRs waiting on them re-evaluate and, with auto-merge on, merge.

### Drop a test

1. 👤 Run the [**Rebuild staging/official**](https://github.com/cal-itp/data-infra/actions/workflows/rebuild-staging.yml) workflow with `drop` set to the staging PR number. (Or let the test expire.)
2. ⚙️ It resets `staging/official` to `main`, re-merges every other running test, and force-pushes. The deploys redeploy the dropped test's files from `main`, and its PR gets a comment.
3. 👤 Clean up anything the test created that `main` doesn't have, such as the tables of new dbt models, or anything created by hand while testing.

To test again later, open a new PR from the same branch into `staging/official`.

### Expiry

Forgotten tests are removed so they don't block others or make staging drift from production.

| when                                                          | what happens                                                     |
| ------------------------------------------------------------- | ---------------------------------------------------------------- |
| 14 days after the test's latest merge into `staging/official` | ⚙️ A comment on the staging PR asks whether you're still testing |
| The PR into `main` is closed without merging                  | ⚙️ The test expires 3 days after it was closed                   |
| 2 days before expiry                                          | ⚙️ A final notice with the removal date                          |
| 21 days                                                       | ⚙️ The test is dropped, as if by `rebuild-staging`               |

To keep testing, 👤 add the **`staging-keep`** label to the staging PR. The monitor removes the label and extends the deadline by 14 days. If another PR is waiting on the test's files, the extension goes to the [steward](#status-and-alerts) instead, who grants it with the `staging-keep-approved` label.

During rollout, automatic removal runs in dry-run mode: expired tests are only listed on the status issue, and the steward removes them.

### Conflicts with `main`

If something merged into `main` changes a file a test holds (only possible with the `staging-check-override` label; see [Checks](#checks)), the sync can't merge `main` into `staging/official` cleanly.

1. ⚙️ The sync drops the test holding the conflicting files (only one test can hold a file) and comments on its staging PR.
2. 👤 The test's author updates `feature/x` from `main` and opens a new PR into `staging/official`.

### Building on another branch

If `feature/b` is based on `feature/a` (or merges it in) and `feature/a`'s test is dropped or expires, `feature/b`'s PR into `main` gets a comment noting that it carries code from a dropped test. It doesn't block merging; check whether that code should ship.

Never merge `staging/official` into your branch, including with GitHub's **Resolve conflicts** or **Update branch** buttons on a PR into `staging/official`. That carries other tests into your branch, and from there into `main`. The `staging/guards` check fails if it happens; recreate the branch from your own commits.

## Checks

### `staging/guards` (PRs into `staging/official`)

| result                                            | meaning                                   | what to do                                                                                                           |
| ------------------------------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| ❌ *Changes iac/*                                 | Infrastructure goes through `main`        | Move the `iac/` change into a PR into `main` (see [Code-reading Terraform modules](#code-reading-terraform-modules)) |
| ❌ *Branch contains staging/official …*           | The branch has `staging/official` history | Recreate the branch from your own commits, updated from `main`                                                       |
| ⏳ *Waiting on staging test #N*                   | A running test holds a file you change    | Nothing; it passes on its own when that test ends. Turn on auto-merge to merge then.                                 |
| ⏳ *Waiting on #N, which is ready to merge first* | An older PR wants the same file           | Nothing; PRs go in order                                                                                             |

Tests can't share files. This is stricter than git needs: if shared files such as `airflow/requirements-c3.txt`, `warehouse/uv.lock`, `warehouse/dbt_project.yml` or `warehouse/packages.yml` end up blocking real work, the rule can be relaxed to "no git conflicts between tests". The other guard would still apply, and `rebuild-staging` would need to handle conflicts between tests.

### `staging/gate` (PRs into `main`)

| result                            | meaning                                                                     | what to do                                                                                         |
| --------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| ✅ *No files under test*          | Nothing you change is being tested                                          | Nothing                                                                                            |
| ✅ *Matches what was tested*      | A promotion that ships exactly what was tested                              | Nothing                                                                                            |
| ❌ *Differs from what was tested* | Your PR carries a tested change but also something else, or a newer version | Update the test with another PR into `staging/official`, or remove the extra change                |
| ⏳ *Waiting on staging test #N*   | You change a file a running test holds                                      | Wait for the test to be promoted or dropped, or ask its owner to include your change in their test |

A PR counts as a promotion if, for any file a test holds, its version equals `staging/official`'s, or if its branch has a running test. Once a test is dropped or expires, it no longer counts as tested.

**Override:** the `staging-check-override` label passes the check, for example for a hotfix. The next sync will then drop the test holding the file.

Both checks are re-evaluated whenever `staging/official` changes and every 30 minutes.

## Code-reading Terraform modules

Three staging modules read files from outside `iac/` and deploy them:

| module                                               | reads                                                    |
| ---------------------------------------------------- | -------------------------------------------------------- |
| `iac/cal-itp-data-infra-staging/airflow/us`          | `airflow/**`, `warehouse/**`                             |
| `iac/cal-itp-data-infra-staging/composer/us`         | `airflow/requirements-c3.txt`, `airflow/.staging_c3.env` |
| `iac/cal-itp-data-infra-staging/gtfs-rt-archiver/us` | `services/gtfs-rt-archiver`                              |

Whichever branch applies them deploys that branch's code, so in staging they're applied **only from `staging/official`** (auto-approved). Their `.tf` files still change through PRs into `main`, and reach staging through the sync.

To test a change to one of them:

1. 👤 Open a PR into `main` that changes only the **staging** module. Its staging plan comment previews `staging/official` with your PR merged in, which is what the sync will apply. Merge it.
2. 👤 Verify it in staging.
3. 👤 Open a second PR into `main` that makes the same change to the **production** module.

When a `.tf` change has to ship with code under test (for example, a new environment variable a DAG reads), land the staging `.tf` change on `main` first. That only works if it's harmless without the code: adding things usually is. For removals and renames, add the new name, migrate the code, then remove the old name.

Applying `iac/cal-itp-data-infra-staging/airflow/us` locally (`terraform apply`) deploys your checkout over whatever `staging/official` deployed. Treat it as break-glass only.

## dbt

PRs no longer write to shared staging. Staging dbt runs happen when changes reach `staging/official`: through a staging test, or through the sync after a merge into `main`.

Every PR that changes models or seeds gets advisory checks and a **dbt CI checks** comment:

- **Empty build:** `dbt build --empty` of the changed models and everything downstream, into `ci_pr_<number>*` datasets in the staging project. It checks SQL, columns and types on empty tables, so data tests pass trivially. Unchanged upstream models are read from the staging datasets; a missing staging table can cause a false failure.
- **Estimated scan:** a BigQuery dry run of each changed and downstream model's full-refresh SQL. Merging into `main` full-refreshes changed models in production, so a large number here is worth a second look. Estimates use **staging** data volumes, which can be much smaller than production's.

The `ci_pr_*` datasets are deleted when the PR closes, and any older than three days are swept daily.

## Status and alerts

- **Status issue** (label `staging-official-status`, pinned): rewritten every 30 minutes with each running test, the files it holds, its deadline and linked PR into `main`, PRs waiting on files, and whether the sync is current. The [compare view `main...staging/official`](https://github.com/cal-itp/data-infra/compare/main...staging/official) shows exactly what staging runs beyond `main`.
- **Incident issue** (label `staging-sync-failure`): opened when the sync fails for a reason other than a conflict, or when `staging/official` has been missing `main` commits for 30 minutes. While that's the case, staging deploys refuse to run, so staging can't roll back `main`'s changes. The issue is assigned to the steward, re-pinged after 24 hours, and closed automatically once `staging/official` contains `main` again.
- **Steward** (repository variable `STAGING_STEWARD`): handles incidents, extension requests while others wait, and removals the automation can't do.

## Workflows

| workflow                    | trigger                                       | does                                                                                                                       |
| --------------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `sync-staging-official.yml` | push to `main`                                | Merges `main` into `staging/official`; drops a conflicting test                                                            |
| `rebuild-staging.yml`       | manual                                        | Drops tests and rebuilds the branch                                                                                        |
| `staging-monitor.yml`       | every 30 minutes                              | Sync freshness, incidents, expiry, status issue, reset when nothing differs from `main`, re-evaluates checks               |
| `staging-guards.yml`        | PRs into and pushes to `staging/official`     | `staging/guards`                                                                                                           |
| `staging-gate.yml`          | PRs into `main`, pushes to `staging/official` | `staging/gate` and the dropped-test warning                                                                                |
| `terraform-apply.yml`       | push to `main` and `staging/official`         | Staging infrastructure from `main`; code-reading modules from `staging/official`; production from `main`                   |
| `composer-apply-files.yml`  | push to `main` and `staging/official`         | Airflow and Composer: staging from `staging/official`, production from `main`                                              |
| `deploy-dbt.yml`            | push to `main` and `staging/official`; PRs    | dbt runs, docs, Metabase and the Airflow upload: staging from `staging/official`, production from `main`; CI checks on PRs |
| `dbt-ci-cleanup.yml`        | PR closed; daily                              | Deletes `ci_pr_*` datasets                                                                                                 |

The automation's logic lives in `.github/scripts/staging_official.py`, tested by `.github/scripts/tests/`.

**What a staging deploy covers.** Each staging deploy workflow records the last commit it deployed successfully in a ref (`refs/deployed/staging/<workflow>`) and deploys the files changed since then, not just since the previous push. A deploy that failed or was skipped (for example while `staging/official` was missing `main` commits) is caught up by the next one. Staging deploy jobs also check out the current tip of `staging/official` once they start, so a slow run can't roll back a newer one. If a staging dbt model keeps failing, every later deploy re-runs it until it's fixed.

## Setup (admins)

- **GitHub App** with repository permissions *Contents: read and write*, *Pull requests: read and write* and *Issues: read and write*, installed on this repository. Store its ID in the variable `STAGING_BOT_APP_ID` and its private key in the secret `STAGING_BOT_PRIVATE_KEY`. Pushes made with the default `GITHUB_TOKEN` wouldn't trigger the staging deploys.
- **Ruleset on `staging/official`:**
  - block deletion and force pushes;
  - require a pull request with 1 approval, merged with a **merge commit** only. Test detection relies on GitHub's default merge commit message (`Merge pull request #N from owner/branch`), so keep the repository's merge commit message setting on "Default message";
  - require the `staging/guards` status;
  - allow the App to bypass (it pushes syncs and rebuilds).
- **Required status on `main`:** `staging/gate`.
- **Variables:**
  - `STAGING_STEWARD`: GitHub usernames, space-separated;
  - `STAGING_TEAM` (optional): a team to mention on incidents, e.g. `cal-itp/data-infra`;
  - `STAGING_AUTO_REMOVE`: `dry-run` (default), `on` or `off`.
- **Labels:** `staging-keep`, `staging-keep-approved`, `staging-check-override`, `staging-sync-failure`, `staging-official-status`.
- **Status issue:** pin it once the monitor creates it.
- **dbt CI:** the staging service account `github-actions-service-account@cal-itp-data-infra-staging.iam.gserviceaccount.com` must be able to create and delete datasets in `cal-itp-data-infra-staging`.
