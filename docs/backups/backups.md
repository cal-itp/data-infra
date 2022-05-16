# Backups

## Metabase Backups
For most of our backups we utilize [Restic] (https://restic.readthedocs.io/en/latest/010_introduction.html)

To verify that metabse configuration backups have been created, there are three pieces of information you require:
1. Name of the Restic Repository
2. Restic password
3. Google Access token

There are several ways to obtain the restic information.

### Google Cloud Engine

Within the kubernetes engine on GCE, go to the side bar of `Secretes and Config Maps`. Select `cluster = data-infra-apps(us-west1)` and `namespace = metabase`. Then select `database-backup`. This will have the rustic password that you will need but it will be encrypted.

### Lens
The preferred method is to use the Lens Kubernetes IDE https://k8slens.dev/. Once Lens desktop is set up, sync the following cluster `gke_cal-itp-data-infra_us-west1_data-infra-apps`. Within the configuration side bar, navigate to `Secrets`. Slect the `database-backup` secret where you will see the `RESTIC_PASSWORD`. Click the eye icon to unencrypt the password.

Then navigate to the Workloads parent folder and select `CronJobs`. Select the cronjob `postgressql-backup`. If you click the edit button you can look at it in yaml form. There you will obtain the restic repository info.
```
name: RESTIC_REPOSITORY
value: gs:calitp-backups-metabase:/
- name: PGHOST
value: database.metabase.svc.cluster.local
```

Once you have the name of the restic repository, the password and your google access token you can connect to restic.
