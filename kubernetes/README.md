# Kubernetes

> :bulb: See the [ci README](../ci/README.md) for the specifics of deploying Kubernetes changes via GitOps. Only workloads (i.e. applications) are deployed via CI/CD and pull requests; changing the Kubernetes cluster itself (e.g. adding a node pool) is a manual operation.

> :notebook: Both the Google Kubernetes Engine UI and the Lens Kubernetes IDE are useful GUI tools for interacting with a Kubernetes cluster, though you can get by with `kubectl` on the command line.

We deploy our applications and services to a Google Kubernetes Engine cluster. If you are unfamiliar with Kubernetes, we recommend reading through [the official tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/) to understand the main components (you do not have to actually perform all the steps).

A [glossary](#Glossary) exists at the end of this document.

## GitOps

The workflows described above also define their triggers. In general, developer workflows should follow these steps.

1. Check out a feature branch
2. Put up a PR for that feature branch, targeting `main`
   - `preview-kubernetes` will run and add a comment showing the diff of changes that will affect the production Kubernetes cluster

      **BE AWARE**: This diff may *NOT* reveal any changes that have been manually applied to the cluster being undone. The `helm diff` plugin used under the hood compares the new manifests against the saved snapshot of the last ones Helm deployed rather than the current state of the cluster. It has to work that way because that most accurately reflects how helm will apply the changes. This is why it is important to avoid making manual changes to the cluster.

3. Merge the PR
   - `deploy-kubernetes` will run and deploy to `prod` this time

## Cluster Administration

We do not currently use Terraform to manage our cluster, nodepools, etc. and major changes to the cluster are unlikely to be necessary, but we do have some bash scripts that can help with tasks such as creating new node pools or creating a test cluster.

First, verify you are logged in and gcloud is pointed at `cal-itp-data-infra` and the `us-west1` region.

```bash
gcloud auth list
gcloud config get-value project
gcloud config get-value compute/region
```

Then, you may get credentials to the cluster (assuming one already exists).

```bash
gcloud container clusters get-credentials data-infra-apps (optionally specifying --region us-west1)
kubectl config get-contexts (prints possible auth contexts; GKE creates them with a defined name format)
kubectl config use-context gke_cal-itp-data-infra_us-west1_data-infra-apps
```

### Deploying the cluster

> :red_circle: You should only run this script if you intend to actually deploy a new cluster, though it will stop if the cluster already exists. This is likely to be a rare operation but may be necessary for migrating regions, creating a totally isolated test cluster, etc.

The cluster level configuration parameters are stored in [config-cluster.sh](./gke/config-cluster.sh). Creating the cluster also requires configuring parameters for a node pool named "default-pool" (unconfigurable name defined by GKE) in [kubernetes/gke/config-nodepool.sh](./gke/config-nodepool.sh). Any additional node pools configured in this file are also stood up at cluster creation time.

Once the cluster is created, it can be managed by pointing the `KUBECONFIG` environment variable to `kubernetes/gke/kube/admin.yaml` or you can follow the above authentication steps.

```bash
./kubernetes/gke/cluster-create.sh
export KUBECONFIG=$PWD/kubernetes/gke/kube/admin.yaml
kubectl cluster-info
```

The cluster can be deleted by running `kubernetes/gke/cluster-delete.sh`.

### Nodepool lifecycle

It's much more likely that a user may want to add or change node pools than make changes to the cluster itself. Certain features of node pools are immutable (e.g. machine type); to change such parameters requires creating a new node pool with the desired new values, migrating workloads off of the old node pool, and then deleting the old node pool. The node pool lifecycle scripts help simplify this process.

#### Create a new node pool

Configure a new node pool by adding its name to the `GKE_NODEPOOL_NAMES` array in [kubernetes/gke/config-nodepool.sh](./gke/config-nodepool.sh). For each nodepool property (`GKE_NODEPOOL_NODE_COUNT`, `GKE_NODEPOOL_NODE_LOCATIONS`, etc) it is required to add an entry to the array which is mapped to the nodepool name. This config file is also where you will set Kubernetes [taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) and [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) on the nodes.

Once the new nodepool is configured, it can be stood up by running `kubernetes/gke/nodepool-up.sh <nodepool-name>`, or by simply running `kubernetes/gke/nodepool-up.sh`, which will stand up all configured node pools which do not yet exist.

#### Drain and delete an old node pool

Once a new nodepool has been created to replace an active node pool, the old node pool must be removed from the `GKE_NODEPOOL_NAMES` array.

Once the old node pool is removed from the array, it can be drained and deleted by running `kubernetes/gke/nodepool-down.sh <nodepool-name>`.

## Deploying workloads

Cluster workloads are divided into two classes:

1. Apps are the workloads that users actually care about; this includes deployed "applications" such as the GTFS-RT archiver but also includes "services" like Grafana and Sentry. These workloads are deployed using `invoke` as defined in the [ci](../ci/) folder.

2. System workloads are used to support running applications. This includes items such as an ingress controller, HTTPS certificate manager, etc. The system deploy command is run at cluster create time, but when new system workloads are added it may need to be run again.

   ```bash
   kubectl apply -k kubernetes/system
   ```

## JupyterHub

JupyterHub is a good example of an application using a Helm chart that is ultimately exposed to the outside internet for user access. In general, any non-secret changes to the chart can be accomplished by modifying the chart's `values.yaml` and running the `invoke release` specific to JupyterHub.

```
poetry run invoke release -f channels/prod.yaml --app=jupyterhub
```

### Secrets

Because we use [Github OAuth](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html?highlight=oauth#github) for user authentication in JupyterHub, we have to provide a client-id and client-secret to the JupyterHub Helm chart. Here is what the full configuration for the GitHub OAuth in our JupyterHub Helm chart's `values.yaml` might look like:

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

We want to avoid committing these secrets to GitHub, but we also want to version control as much of the `values.yaml` as possible. Fortunately, the JupyterHub chart affords us the ability to use the `hub.existingSecret` parameter to referencing an existing secret containing additional `values.yaml` entries. For GitHub OAuth specifically, the `jupyterhub-github-config` secret must contain a `values.yaml` key containing a base64-encoded representation of the following yaml:

```yaml
hub:
  config:
    GitHubOAuthenticator:
      client_id: <your-client-id-here>
      client_secret: <your-client-secret-here>
```

This encoding could be accomplished by calling `cat <the secret yaml file> | base64` or using similar CLI tools; do not use an online base64 converter for secrets!

### Domain Name Changes

At the time of this writing, a JupyterHub deployment is available at [https://notebooks.calitp.org](https://notebooks.calitp.org). If this domain name needs to change, the following configurations must also change so OAuth and ingress continue to function.

1. Within the GitHub OAuth application, in Github, the homepage and callback URLs would need to be changed. Cal-ITP owns the Github OAUth application in GitHub, and [this Cal-ITP Github issue](https://github.com/cal-itp/data-infra/issues/367) can be referenced for individual contributors who may be able to helm adjusting the Github OAUth application's homepage and callback URLs.

2. After the changes have been made to the GitHub OAuth application, the following portions of the JupyterHub chart's `values.yaml` must be changed:

- `hub.config.GitHubOAuthenticator.oauth_callback_url`
- `ingress.hosts`
- `ingress.tls.hosts`

## Backups

For most of our backups we utilize [Restic](https://restic.readthedocs.io/en/latest/010_introduction.html); this section uses the Metabase database backup as an example.

To verify that Metabase configuration backups have been created, there are three pieces of information you require:

1. Name of the Restic repository
2. Restic password
3. Google Access token (if you have previously authenticated to `gcloud`, this should already be complete)

There are several ways to obtain the Restic information, listed in order of effort.

1. In Google Cloud Console, find the `database-backup` K8s Secret in the appropriate namespace (e.g. `metabase`) in the data-infra-apps cluster
2. Perform #1 but using the [Lens Kubernetes IDE](https://k8slens.dev)
3. Print out the K8s Secret and decode from base64 using `kubectl` and `jq`
4. Determine the name of the secret from the deployment YAML (e.g. `metabase_database-backup`) and track it down in Google Cloud Secret Manager; the secrets generally follow the pattern of `<k8s-namespace>_<secret-name`
5. Look at the K8s configuration of the CronJob that performs the backup (e.g. `postgresql-backup`) from the deployment YAML; this can be accomplished via Google Cloud, Lens, or kubectl

## Restic

Within Restic you can see the snapshots by running the following terminal commands:

`restic list snapshot` or `restic snapshots latest`

For spot testing, create a folder within the tmp directory
`mkdir /tmp/pgdump` then run the Restic restore command to extract the data from a snapshot.

`restic restore -t /tmp/pgdump latest`

This will be a zipped file, unzip it by using

`gunzip /tmp/pgdump/pg_dumpall.sql`

## Verify SQL in Postgres

To verify the SQL schema and underlying data has not been corrupted, open the SQL file within a Docker container. For initial Docker container setup please visit [Docker Documentation](https://docs.docker.com/get-started/)

`docker run --rm -v /tmp/sql:/workspace -e POSTGRES_HOST_AUTH_METHOD=trust postgres:13.5`

It is important to note that the version of Postgres used to take the Metabase snapshots (13.5) needs to be the same version of Postgres that is restoring the dump.

To load the SQL into Postgres, run the following command:

`psql -U postgres < pg_dumpall.sql`

Then you can verify the schema and underlying data within postgres.

## Glossary

> Mostly cribbed from the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads)

- Kubernetes - a platform for orchestrating (i.e. deploying) containerized software applications onto a collection of virtual machines
- Cluster - a collection of virtual machines (i.e. nodes) on which Kubernetes is installed, and onto which Kubernetes in turn deploys pods
- Pod - one (or more) containers deployed to run within a Kubernetes cluster
  - For deployed services/applications, Pods exist because of a Deployment
  - For ephemeral workloads (think Airflow tasks or database backups), Pods may be managed directly or via a Job
- Deployment - a Kubernetes object that manages a set of Pods, such as multiple replicas of the same web application
  - StatefulSet - similar to Deployments but provides guarantees (e.g. deterministic network identifiers) necessary for stateful applications such as databases
- Service - an abstraction around Pods that provides a network interface _within the cluster_
  - For example, a Redis instance needs a Service to be usable by other Pods
- Ingress - exposes Services to the outside world
  - For example, a Metabase Service needs an Ingress to be accessible from the internet
- Volume - an abstraction of storage that is typically mounted into the file system of Pods
- Secrets/ConfigMaps - an abstraction of configuration information, typically mounted as environment variables of or files within Pods
