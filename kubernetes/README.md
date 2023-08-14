# Kubernetes

We deploy our applications and services to a Google Kubernetes Engine cluster. If you are unfamiliar with Kubernetes, we recommend reading through [the official tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/) to understand the main components (you do not have to actually perform all the steps).

## Cluster Administration

We do not currently use Terraform to manage our cluster, nodepools, etc. and major changes to the cluster are unlikely to be necessary, but we do have some bash scripts that can help with tasks such as creating new node pools or creating a test cluster.

First, verify you are logged in and gcloud is pointed at `cal-itp-data-infra` and the `us-west1` region.
```bash
gcloud auth list
gcloud config get-value project
gcloud config get-value compute/region
```

### quick start ###

```bash
./kubernetes/gke/cluster-create.sh
# ...
export KUBECONFIG=$PWD/kubernetes/gke/kube/admin.yaml
kubectl cluster-info
```

### cluster lifecycle ###

Create the cluster by running `kubernetes/gke/cluster-create.sh`.

The cluster level configuration parameters are stored in
[`kubernetes/gke/config-cluster.sh`](https://github.com/cal-itp/data-infra/blob/main/kubernetes/gke/config-cluster.sh).
Creating the cluster also requires configuring parameters for a node pool
named "default-pool" (unconfigurable name defined by GKE) in
[`kubernetes/gke/config-nodepool.sh`](https://github.com/cal-itp/data-infra/blob/main/kubernetes/gke/config-nodepool.sh).
Any additional node pools configured in this file are also stood up at cluster
creation time.

Once the cluster is created, it can be managed by pointing the `KUBECONFIG`
environment variable to `kubernetes/gke/kube/admin.yaml`.

The cluster can be deleted by running `kubernetes/gke/cluster-delete.sh`.

### nodepool lifecycle ###

Certain features of node pools are immutable (e.g., machine type); to change
such parameters requires creating a new node pool with the desired new values,
migrating workloads off of the old node pool, and then deleting the old node pool.
The node pool lifecycle scripts help simplify this process.

#### create a new node pool ####

Configure a new node pool by adding its name to the `GKE_NODEPOOL_NAMES` array
in [`kubernetes/gke/config-nodepool.sh`](https://github.com/cal-itp/data-infra/blob/main/kubernetes/gke/config-nodepool.sh).
For each nodepool property (`GKE_NODEPOOL_NODE_COUNT`, `GKE_NODEPOOL_NODE_LOCATIONS`, etc)
it is required to add an entry to the array which is mapped to the nodepool name.

Once the new nodepool is configured, it can be stood up by running `kubernetes/gke/nodepool-up.sh [nodepool-name]`,
or by simply running `kubernetes/gke/nodepool-up.sh`, which will stand up all configured node pools which do not yet
exist.

#### drain and delete an old node pool ####

Once a new nodepool has been created to replace an active node pool, the old node pool must be
removed from the `GKE_NODEPOOL_NAMES` array.

Once the old node pool is removed from the array, it can be drained and deleted by running `kubernetes/gke/nodepool-down.sh <nodepool-name>`.

## Deploy Cluster Workloads ##

Cluster workloads are divided into two classes:

1. Apps
2. System

Apps are the workloads that users actually care about; this includes deployed "applications"
such as the GTFS-RT archiver but also includes "services" like Grafana and Sentry.

System workloads are used to support running applications. This includes items
such as an ingress controller, HTTPS certificate manager, etc. The system deploy command
is run at cluster create time, but when new system workloads are added it may need
to be run again.

```bash
kubectl apply -k kubernetes/system
```

# JupyterHub

This page outlines how to deploy JupyterHub to Cal-ITP's Kubernetes cluster.

As we are not yet able to commit encrypted secrets to the cluster, we'll have to do some work ahead of a `helm install`.

## Installation

### 1. Create the Namespace

```
kubectl create ns jupyterhub
```

### 2. Add Secrets to Namespace

JupyterHub relies on two secrets ( and ); these are stored in Secret Manager and are deployable via invoke.

From the `ci` directory:
```
poetry run invoke secrets -f channels/prod.yaml --app=jupyterhub
```

#### jupyterhub-gcloud-service-key

The GCloud service key, a .json file, is used to authenticate users to GCloud.

Currently, the secret `jupyterhub-gcloud-service-key` is mounted to every JupyterHub user's running container at `/usr/local/secrets/service-key.json`. As we refine our authentication approach, this secret may become obsolete and may be removed from this process, but for now the process of volume mounting this secret is required for authentication.


#### jupyterhub-github-config

Because we use [Github OAuth](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html?highlight=oauth#github) for user authentication in JupyterHub, we have to provide a client-id and client-secret to the JupyterHub Helm chart. We also have to provide a bunch of non-sensitive information to the chart, as well, for GitHub OAuth to function.

For context, here is what the full configuration for the GitHub OAuth in our JupyterHub Helm chart's `values.yaml` might look like:

```yaml
hub:
  config:
    GitHubOAuthenticator:
      client_id: <your-client-id-here>
      client_secret: <your-client-secret-here>
      oauth_callback_url: https://your-jupyterhub-domain/hub/oauth_callback
      allowed_organizations:
        - cal-itp:warehouse-users
      scope:
        - read:org
    JupyterHub:
      authenticator_class: github
      Authenticator:
        admin_users:
          - machow
          - themightchris
          - lottspot
```

Fortunately, we don't have to store all of this information in the secret! The JupyterHub chart affords us the ability to use the `hub.existingSecret` parameter to pass in the sensitive information, so we can mix-and-match parts of the configuration.

This means that we can leave parameters like `hub.config.GitHubOAuthenticator.oauth_callback_url` and `hub.config.GitHubOAuthenticator.allowed_organizations` in plain text in our `values.yaml`, and place sensitive information like `hub.config.GitHubOAuthenticator.client_id` and `hub.config.GitHubOAuthenticator.client_secret` in our `jupyterhub-secrets.yaml`.

So, what format must our base64 encoded string take in order for the JuptyerHub chart to accept it?

##### Create a Temporary File

```
touch github-secrets.yaml
```

##### Fill the File with Chart-Formatted Secrets

Your `github-secrets.yaml` should look like this:

```yaml
hub:
  config:
    GitHubOAuthenticator:
      client_id: <your-client-id-here>
      client_secret: <your-client-secret-here>
```

### 3. Deploying the application

You are now ready to install the chart to your cluster using invoke (which calls helm underneath).

```
poetry run invoke release -f channels/prod.yaml --app=jupyterhub
```

In general, any non-secret changes to the chart can be accomplished by modifying the chart's `values.yaml` and running the `invoke release` from above.


## Domain Name Changes

At the time of this writing, a JupyterHub deployment is available at `https://hubtest.k8s.calitp.jarv.us`.

If, in the future, the domain name were to change to something more permanent, some configuration would have to change. Fortunately, though, none of the secrets we covered above are affected by these configuration changes!

It is advised the below changes are planned and executed in a coordinated effort.

### Changes in GitHub OAuth

Within the GitHub OAuth application, in Github, the homepage and callback URLs would need to be changed. Cal-ITP owns the Github OAUth application in GitHub, and [this Cal-ITP Github issue](https://github.com/cal-itp/data-infra/issues/367) can be referenced for individual contributors who may be able to helm adjusting the Github OAUth application's homepage and callback URLs.

### Changes in the Helm Chart

After the changes have been made to the GitHub OAuth application, the following portions of the JupyterHub chart's `values.yaml` must be changed:

  - `hub.config.GitHubOAuthenticator.oauth_callback_url`
  - `ingress.hosts`
  - `ingress.tls.hosts`

# Backups

## Metabase

For most of our backups we utilize [Restic](https://restic.readthedocs.io/en/latest/010_introduction.html)

To verify that metabase configuration backups have been created, there are three pieces of information you require:

1. Name of the Restic repository
2. Restic password
3. Google Access token

There are several ways to obtain the Restic information.

## Google Cloud Engine

Within the kubernetes engine on GCE, go to the sidebar of `Secrets and Config Maps`. Select `cluster = data-infra-apps(us-west1)` and `namespace = metabase`, then select `database-backup`. This will have the Restic password that you will need but it will be encrypted.

## Lens

The preferred method is to use the Lens Kubernetes IDE https://k8slens.dev/. Once Lens desktop is set up, sync the following cluster `gke_cal-itp-data-infra_us-west1_data-infra-apps`. Within the configuration sidebar, navigate to `Secrets`. Select the `database-backup` secret where you will see the `RESTIC_PASSWORD`. Click the eye icon to unencrypt the password.

Navigate to the Workloads parent folder and select `CronJobs`. Select the cronjob `postgresql-backup`. If you click the edit button you can look at it in YAML form. There you will obtain the Restic repository info.

```shell
name: RESTIC_REPOSITORY
value: gs:calitp-backups-metabase:/
- name: PGHOST
value: database.metabase.svc.cluster.local
```

Once you have the name of the Restic repository, the password and your google access token you can connect to Restic.

## Restic

Within Restic you can see the snapshots by running the following terminal commands:

`restic list snapshot` or `restic snapshots latest`

For spot testing, create a folder within the tmp directory
`mkdir /tmp/pgdump` then run the Restic restore command to extract the data from a snapshot.

`restic restore -t /tmp/pgdump latest`

This will be a zipped file, unzip it by using

`gunzip /tmp/pgdump/pg_dumpall.sql`

## Verify SQL in Postgres

To verify the SQL schema and underlying data has not been corrupted , open the SQL file within a Docker container. For initial Docker container setup please visit [Docker Documentation](https://docs.docker.com/get-started/)

`docker run --rm -v /tmp/sql:/workspace -e POSTGRES_HOST_AUTH_METHOD=trust postgres:13.5`

It is important to note that the version of postgres used to take the metabase snapshots (13.5) needs to be the same version of postgres that is restoring the dump.

To load the sql into postgres, run the following command:

`psql -U postgres < pg_dumpall.sql`

Then you can verify the schema and underlying data within postgres.
