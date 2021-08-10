FROM fedora:34
RUN useradd -s /bin/bash -u 1000 -Umd /home/ci ci
ADD google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo
ADD docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN dnf -y install \
  google-cloud-sdk \
  docker-ce-cli    && dnf clean all
RUN usermod -aG docker ci
USER ci
WORKDIR /home/ci
