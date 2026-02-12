# jupyterhub-singleuser image

This is the notebook image that individual users are served
via JupyterHub.

## Testing Changes

A person with Docker set up locally can build a new version of the image at any time after making changes.

This can check for any significant security issues with this build using the (Safety package)[https://pypi.org/project/safety/]
```
pip install safety
safety scan 
```

### Helpful Docker commands
1. Remove all unused containers, networks, and images
```
docker system prune -a
```

2. Build an image and record success and error output to terminal and build.log file
```
docker build  -t test-image-name . 2>&1 | tee build.log
```

3. Access a bash terminal in the image:
```
docker run -it test-image-name bash
```
Or if you need root user access in the image: 
```
docker container exec -u root -it test-image-name bash
```

4. Pull an image from GHCR and run its JupyterLab locally

In order to emulate the platform the image was built for, you will want to pass a special `--platform` flag
```
docker image pull ghcr.io/cal-itp/data-infra/jupyter-singleuser:image-version
docker run --platform linux/amd64 -p 8888:8888 ghcr.io/cal-itp/data-infra/jupyter-singleuser:image-version
# Then visit the URL it outputs in your browser
```

If you want to run multiple instances at the same time in order to do some comparison between images, simply map any subsequent image to a different port
```
docker run --platform linux/amd64 -p 9999:8888 ghcr.io/cal-itp/data-infra/jupyter-singleuser:another-image-version
# You may need to manually modify the URL it outputs to match your custom port
```

## Deploying Changes to Production

When changes are finalized, a new version number should be specified in [pyproject.toml](./pyproject.toml). When changes to this directory are merged into `main`, [a GitHub Action](../../.github/workflows/build-jupyter-singleuser-image.yml) automatically publishes an updated version of the image.

After deploying, you will likely need to change references to the version of the image in use by Kubernetes-managed services, such as [here](../../kubernetes/apps/charts/jupyterhub/values.yaml). See [our GitHub workflows documentation](../../kubernetes/README.md#gitops) for how to manage deployment of updated Kubernetes services and their associated workloads.
