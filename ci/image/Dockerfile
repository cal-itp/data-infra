FROM ubuntu:20.04
RUN useradd -s /bin/bash -u 1000 -Umd /home/ci ci
ADD prepare-os-ubuntu.sh /bootstrap.sh
RUN  /bootstrap.sh && rm -rf /var/lib/apt/lists/* /bootstrap.sh
USER ci
WORKDIR /home/ci
