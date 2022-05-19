# Backups

## Metabase Backups

For most of our backups we utilize [Restic](https://restic.readthedocs.io/en/latest/010_introduction.html)

To verify that metabase configuration backups have been created, there are three pieces of information you require:

1. Name of the Restic repository
2. Restic password
3. Google Access token

There are several ways to obtain the Restic information.

### Google Cloud Engine

Within the kubernetes engine on GCE, go to the sidebar of `Secrets and Config Maps`. Select `cluster = data-infra-apps(us-west1)` and `namespace = metabase`, then select `database-backup`. This will have the Restic password that you will need but it will be encrypted.

### Lens

The preferred method is to use the Lens Kubernetes IDE https://k8slens.dev/. Once Lens desktop is set up, sync the following cluster `gke_cal-itp-data-infra_us-west1_data-infra-apps`. Within the configuration sidebar, navigate to `Secrets`. Select the `database-backup` secret where you will see the `RESTIC_PASSWORD`. Click the eye icon to unencrypt the password.

Navigate to the Workloads parent folder and select `CronJobs`. Select the cronjob `postgressql-backup`. If you click the edit button you can look at it in YAML form. There you will obtain the Restic repository info.

```shell
name: RESTIC_REPOSITORY
value: gs:calitp-backups-metabase:/
- name: PGHOST
value: database.metabase.svc.cluster.local
```

Once you have the name of the Restic repository, the password and your google access token you can connect to Restic.

### Restic

Within Restic you can see the snapshots by running the following terminal commands:

`restic list snapshot` or `restic snapshots latest`

For spot testing, create a folder within the tmp directory
`mkdir /tmp/pgdump` then run the Restic restore command to extract the data from a snapshot.

`restic restore -t /tmp/pgdump latest`

This will be a zipped file, unzip it by using

`gunzip /tmp/pgdump/pg_dumpall.sql`

### Verify SQL in Postgres

To verify the SQL schema and underlying data has not been corrupted , open the SQL file within a Docker container. For initial Docker container setup please visit [Docker Documentation](https://docs.docker.com/get-started/)

`docker run --rm -v /tmp/sql:/workspace -e POSTGRES_HOST_AUTH_METHOD=trust postgres:13.5`

It is important to note that the version of postgres used to take the metabase snapshots (13.5) needs to be the same version of postgres that is restoring the dump.

To load the sql into postgres, run the following command:

`psql -U postgres < pg_dumpall.sql`

Then you can verify the schema and underlying data within postgres.
