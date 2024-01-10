# jupyterhub-singleuser image

This is the notebook image that individual users are served
via JupyterHub.

## Testing Changes

A person with Docker set up locally can build a new version of the image at any time after making changes.

```bash
docker build -t ghcr.io/cal-itp/data-infra/jupyter-singleuser:[NEW VERSION TAG] .
```

## Deploying Changes to Production

When changes are finalized, a new version number should be specified in [pyproject.toml](./pyproject.toml). When changes to this directory are merged into `main`, [a GitHub Action](../../.github/workflows/build-jupyter-singleuser-image.yml) automatically publishes an updated version of the image. A contributor with proper GHCR permissions can also manually deploy a new version of the image via the CLI:

```bash
docker build -t ghcr.io/cal-itp/data-infra/jupyter-singleuser:[NEW VERSION TAG] .
docker push ghcr.io/cal-itp/data-infra/jupyter-singleuser:[NEW VERSION TAG]
```

After deploying, you will likely need to change references to the version of the image in use by Kubernetes-managed services, such as [here](../../kubernetes/apps/charts/jupyterhub/values.yaml). See [our GitHub workflows documentation](../../kubernetes/README.md#gitops) for how to manage deployment of updated Kubernetes services and their associated workloads.
