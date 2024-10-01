FROM apache/airflow:2.4.3-python3.9

# install gcloud as root, then switch back to airflow
USER root

RUN apt-get update \
  && apt-get install -y git gdal-bin libgdal-dev g++ \
  && rm -rf /var/lib/apt/lists/*

RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal
RUN export C_INCLUDE_PATH=/usr/include/gdal

RUN curl https://sdk.cloud.google.com > install.sh \
    && sudo bash install.sh --disable-prompts --install-dir=/usr/local/

ENV PATH=$PATH:/usr/local/google-cloud-sdk/bin
RUN gcloud components install gke-gcloud-auth-plugin

USER airflow

COPY requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir --user -r /tmp/requirements.txt
