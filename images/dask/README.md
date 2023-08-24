# dask image

This image exists to add necessary dependencies for dask schedulers
and workers, such as the Prometheus client and Python libraries
used by analytics code. See [the dask docs](https://docs.dask.org/en/stable/how-to/manage-environments.html)
for some additional detail.

## Building and pushing manually

```bash
docker build -t ghcr.io/cal-itp/data-infra/dask:2022.10.13 .
docker push ghcr.io/cal-itp/data-infra/dask:2022.10.13
```
