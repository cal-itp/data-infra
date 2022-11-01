FROM jupyter/datascience-notebook

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

USER root
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
# GitHub CLI https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt update \
    && apt install -y keychain nodejs git-lfs gh libspatialindex-dev graphviz
USER $NB_UID
RUN npm install -g --unsafe-perm=true --allow-root netlify-cli

# gcloud CLI https://cloud.google.com/sdk/docs/install#deb
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-377.0.0-linux-x86_64.tar.gz \
    && tar -zxvf google-cloud-sdk-377.0.0-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$HOME/.local/bin:$PATH"

# TODO: move back to poetry once we shrink the dependcies...
#COPY ./pyproject.toml /reqs/pyproject.toml
#COPY ./poetry.lock /reqs/poetry.lock
#RUN poetry config virtualenvs.create false
#RUN cd /reqs && poetry install
COPY ./requirements.txt /reqs/requirements.txt
RUN pip install -r /reqs/requirements.txt

RUN mkdir /opt/conda/share/jupyter/lab/settings/
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json

COPY ./profile.sh /tmp/profile.sh
COPY ./dask_config.yml /opt/conda/etc/dask/dask_config.yml
