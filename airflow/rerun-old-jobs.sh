#!/usr/bin/env bash

set -ex

DATE=$1
ENVIRONMENT=calitp-composer
PROJECT=cal-itp-data-infra
LOCATION=us-west2
DAG=parse_and_validate_rt

gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T00:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T01:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T02:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T03:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T04:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T05:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T06:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T07:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T08:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T09:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T10:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T11:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T12:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T13:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T14:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T15:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T16:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T17:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T18:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T19:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T20:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T21:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T22:15:00+00:00"
gcloud composer environments run ${ENVIRONMENT} --project ${PROJECT} --location ${LOCATION} dags trigger -- ${DAG} -e "${DATE}T23:15:00+00:00"
