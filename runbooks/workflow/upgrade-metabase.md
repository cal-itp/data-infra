# Upgrading Metabase

Metabase upgrades happen in two phases: validation and release.

## Validation

When Metabase detects a version change, it runs a set of database migrations. In order to prevent this migration from causing an outage, you should validate the new version against the `metabase-test` namespace. There are three steps involved: retrieving a `metabase` database snapshot, restoring the snapshot to the `metabase-test` database, and setting the Docker image tag version. It is important to run the Validation steps below in the `metabase-test` namespace in order to prevent data loss.

### Prerequisites

- Lens (https://k8slens.dev)
- Restic (https://restic.net)
- A copy of the secrets for the GCloud service account

### Service Credentials

1. Log into GCloud: `gcloud auth login`
2. List the clusters you can access: `gcloud container clusters list`
3. Pull Kubernetes credentials for the `data-infra-apps` cluster to your local machine: `gcloud container clusters get-credentials data-infra-apps --location us-west1`

### Replicating the database

1. Retrieve environment variables for one of the `metabase-test` `postgresql-backup` pods
2. Set the `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_PROJECT_ID`, `RESTIC_REPOSITORY` and `RESTIC_PASSWORD` environment variables in a shell
3. List available Restic snapshots using `restic snapshots` and note the latest SHA
4. Download the latest snapshot `restic dump -t pg_dumpall.sql.gz <SHA> /pg_dumpall.sql.gz`
5. Uncompress the dump and make sure it is a complete dump including both schema and data

### Restoring the database

> ⚠️**IMPORTANT**⚠️ Every step here should be run against the `metabase-test` namespace to prevent data loss in production.

1. Visit the test instance at https://metabase-test.k8s.calitp.jarv.us/ to see that login and reporting work as expected
2. Connect to the database instance `kubectl -n metabase-test exec -it database-0 -- bash`
3. Ensure that `psql` can connect: `psql -U admin postgres`
4. Scale the `metabase` ReplicaSet to zero: `kubectl -n metabase-test scale deployment metabase --replicas=0`
5. Restore the dump to the test database: `cat pg_dumpall.sql | kubectl -n metabase-test exec -it database-0 -- psql -U admin postgres`
6. Scale the `metabase ReplicaSet` to 1: `kubectl -n metabase-test scale deployment metabase --replicas=1`
7. Ensure that the test instance still works

### Upgrading Metabase

1. Manually edit the ReplicaSet configuration for the `metabase` ReplicaSet to set the version number
2. Save the configuration
3. Watch the logs for the `metabase` pod until the migrations run: `kubectl -n metabase-test logs deployment/metabase --follow`
4. Visit the test instance to see that login and reporting work as expected

## Release

1. Update the test version in `kubernetes/apps/values/metabase-test.yaml` to the version specified when editing above
2. Update the production version in `kubernetes/apps/values/metabase.yaml` to the same
3. Create a pull request
4. Wait for the `preview-kubernetes` Github Action to run and display a diff for the Docker image tags
5. Ensure those tags match the intended updates to `metabase` and `metabase-test`
