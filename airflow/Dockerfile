FROM apache/airflow:2.10.2-python3.11

# install gcloud as root, then switch back to airflow
USER root

RUN apt-get update \
  && apt-get install -y git \
  && rm -rf /var/lib/apt/lists/*

RUN curl https://sdk.cloud.google.com > install.sh \
    && sudo bash install.sh --disable-prompts --install-dir=/usr/local/

ENV PATH=$PATH:/usr/local/google-cloud-sdk/bin
RUN gcloud components install gke-gcloud-auth-plugin

USER airflow

COPY requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir -r /tmp/requirements.txt
