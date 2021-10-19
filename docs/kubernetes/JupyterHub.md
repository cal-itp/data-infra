# JupyterHub

This page outlines how to deploy JupyterHub to Cal-ITP's Kubernetes cluster.

As we are not yet able to commit encrypted secrets to the cluster, we'll have to do some work ahead of a `helm install`.

## Installation

### 1. Create the Namespace

```
kubectl create ns jupyterhub
```

### 2. Add Secrets to Namespace

Two base64-encoded secrets must be added to the `jupyterhub` namespace before installing the Helm chart.

We'll cover the purpose of each secret in the subsections below.

We'll put both of these secrets in a local file, `jupyterhub-secrets.yaml`, which will contain something that looks like this:

```yaml
apiVersion: v1
data:
  service-key.json: <your-base64-encoded-service-key-here>
kind: Secret
metadata:
  name: jupyterhub-gcloud-service-key
  namespace: jupyterhub
---

apiVersion: v1
data:
  values.yaml: <your-base64-encoded-github-oauth-config-here>
kind: Secret
metadata:
  name: jupyterhub-github-config
  namespace: jupyterhub
```

With the above configured, we can go ahead and apply:

```
kubectl apply -f jupyterhub-secrets.yaml
```

**This file should never be committed!!!**

#### jupyterhub-gcloud-service-key

The GCloud service key, a .json file, is used to authenticate users to GCloud.

Currently, the secret `jupyterhub-gcloud-service-key` is mounted to every JupyterHub user's running container at `/usr/local/secrets/service-key.json`. As we refine our authentication approach, this secret may become obsolete and may be removed from this process, but for now the process of volume mounting this secret is required for authentication.

To create the base64 encoded string from your terminal:

```
cat the-service-key.json | base64 -w 0
```

Then add the terminal's output to the `jupyterhub-secrets.yaml` outlined above.

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

##### Encode the File Contents

From your terminal:

```
cat github-secrets.yaml | base64 -w 0
```

##### Add the Encoding to Your Secret

Add the terminal output from above to your `jupyterhub-secrets.yaml` file.

##### Clean up

From your terminal:

```
rm github-secrets.yaml
```

#### Reminder - Apply the secrets file!

This was a long section, don't forget to apply the following before proceeding.

```
kubectl apply -f jupyterhub-secrets.yaml
```

After you apply it - you should delete it or keep it somewhere very safe!

### 3. Install the Helm Chart

You are now ready to install the chart to your cluster using Helm.

```
helm dependency update  kubernetes/apps/charts/jupyterhub
helm install jupyterhub kubernetes/apps/charts/jupyterhub -n jupyterhub
```

## Updating

In general, any non-secret changes to the chart can be added to / adjusted in the chart's `values.yaml`.

Upgrade with:

```
# On changes to dependencies in Chart.yaml, remember to re-run:
# helm dependency update kubernetes/apps/charts/jupyterhub
helm upgrade jupyterhub kubernetes/apps/charts/jupyterhub -n jupyterhub
```

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

Apply these chart changes with:

```
helm upgrade jupyterhub kubernetes/apps/charts/jupyterhub -n jupyterhub
```
