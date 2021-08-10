FROM ubuntu:20.04
RUN useradd -s /bin/bash -u 1000 -Umd /home/ci ci
RUN apt-get update && apt-get -y install apt-transport-https ca-certificates gnupg curl && rm -rf /var/lib/apt/lists/*
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
ADD google-cloud-sdk.list /etc/apt/sources.list.d/google-cloud-sdk.list
ADD docker-ce.list /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get -y install \
  google-cloud-sdk \
  docker-ce-cli    && rm -rf /var/lib/apt/lists/*
USER ci
WORKDIR /home/ci
