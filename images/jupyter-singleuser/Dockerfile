FROM jupyter/datascience-notebook:python-3.9

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

USER root
RUN apt update \
    && apt install -y curl keychain nodejs git-lfs libspatialindex-dev graphviz libgraphviz-dev
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
# GitHub CLI https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt update \
    && apt install -y gh


# create these ahead of time, then chown to to the notebook user
ENV GCLOUD_HOME=/gcloud
ENV POETRY_HOME="/poetry"
RUN mkdir $POETRY_HOME \
    && chown $NB_USER $POETRY_HOME \
    && mkdir $GCLOUD_HOME \
    && chown $NB_USER $GCLOUD_HOME

USER $NB_UID

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

RUN npm install -g --unsafe-perm=true --allow-root netlify-cli vega-cli vega-lite sql-language-server

# gcloud CLI https://cloud.google.com/sdk/docs/install#deb
RUN cd $GCLOUD_HOME \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-423.0.0-linux-x86_64.tar.gz \
    && tar -zxvf google-cloud-cli-423.0.0-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh
ENV PATH="$GCLOUD_HOME/google-cloud-sdk/bin:$PATH"

COPY ./pyproject.toml /reqs/pyproject.toml
COPY ./poetry.lock /reqs/poetry.lock
RUN poetry config virtualenvs.create false
RUN cd /reqs && poetry install --with=shared_utils
RUN poetry config virtualenvs.create true

ENV DBT_PROFILES_DIR=/home/jovyan/.dbt/
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json
COPY ./profile.sh /tmp/profile.sh
COPY ./dask_config.yml /opt/conda/etc/dask/dask_config.yml
