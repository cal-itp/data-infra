# dask Image

This image exists to add necessary dependencies for Dask schedulers
and workers, such as the Prometheus client and Python libraries
used by analytics code. See [the Dask docs](https://docs.dask.org/en/stable/how-to/manage-environments.html)
for some additional detail.

## Testing Changes

A person with Docker set up locally can build a new version of the Dask image at any time after making changes.

```bash
docker build -t ghcr.io/cal-itp/data-infra/dask:[NEW VERSION TAG] .
```

## Deploying Changes to Production

When changes are finalized, a new version number should be specified in [version.txt](./version.txt). When changes to this directory are merged into `main`, [a GitHub Action](../../.github/workflows/build-dask-image.yml) automatically publishes an updated version of the Dask image. A contributor with proper GHCR permissions can also manually deploy a new version of the image via the CLI:

```bash
docker build -t ghcr.io/cal-itp/data-infra/dask:[NEW VERSION TAG] .
docker push ghcr.io/cal-itp/data-infra/dask:[NEW VERSION TAG]
```

After deploying, you will likely need to change references to the version of the image in use by Kubernetes-managed services, such as [here](../../kubernetes/apps/charts/dask/values.yaml). See [our GitHub workflows documentation](../../.github/workflows#service-yml-workflows) for how to manage deployment of updated Kubernetes services and their associated workloads.
