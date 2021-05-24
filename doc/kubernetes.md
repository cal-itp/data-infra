kubernetes
==========

## Cluster Administration ##

### preflight ###

Check logged in user

```bash
gcloud auth list
# ensure correct active user
# gcloud auth login
```

Check active project

```bash
gcloud config get-value project
# project should be cal-itp-data-infra
# gcloud config set project cal-itp-data-infra
```

Check compute region

```bash
gcloud config get-value compute/region
# region should be us-west1
# gcloud config set compute/region us-west1
```
