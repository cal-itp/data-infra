# jupyterhub-singleuser image

This is the notebook image that individual users are served
via JupyterHub.

## Building and pushing manually

```bash
docker build -t ghcr.io/cal-itp/data-infra/jupyter-singleuser:2022.10.13 .
docker push ghcr.io/cal-itp/data-infra/jupyter-singleuser:2022.10.13
```
