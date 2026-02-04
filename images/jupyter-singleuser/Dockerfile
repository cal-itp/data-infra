FROM quay.io/jupyter/datascience-notebook:python-3.11.10
LABEL org.opencontainers.image.source=https://github.com/cal-itp/data-infra

USER root
RUN apt-get update
RUN apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
# I don't think this nodejs gets used.
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt update \
    && apt-get install -y keychain nodejs git-lfs libspatialindex-dev graphviz libgraphviz-dev
# GitHub CLI https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt update \
    && apt install -y gh
RUN apt-get install -y gdal-bin libgdal-dev # for rasterio

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update && apt-get -y install chromium-browser

# create these ahead of time, then chown to the notebook user
ENV GCLOUD_HOME=/gcloud
RUN mkdir $GCLOUD_HOME && chown $NB_USER $GCLOUD_HOME
RUN mkdir /reqs && chown $NB_USER /reqs

USER $NB_UID

RUN curl -LsSf https://astral.sh/uv/0.9.26/install.sh | sh
ENV PATH="$HOME/.local/bin:$PATH"

RUN npm install -g --unsafe-perm=true --allow-root netlify-cli
RUN npm install -g --unsafe-perm=true --allow-root sql-language-server
# gcloud CLI https://cloud.google.com/sdk/docs/install#deb
RUN cd $GCLOUD_HOME \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-529.0.0-linux-x86_64.tar.gz \
    && tar -zxvf google-cloud-cli-529.0.0-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh
ENV PATH="$GCLOUD_HOME/google-cloud-sdk/bin:$PATH"

COPY ./pyproject.toml /reqs/pyproject.toml
COPY ./uv.lock /reqs/uv.lock

RUN cd /reqs && uv pip install --system --requirements pyproject.toml
RUN cd /reqs && uv tree # print out the package versions and dependencies for documentation
ENV DBT_PROFILES_DIR=/home/jovyan/.dbt/
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json
COPY ./dask_config.yml /opt/conda/etc/dask/dask_config.yml
# These are in /tmp because we will copy in postStart hook
COPY ./profile.sh /tmp/profile.sh
COPY ./jupyter_notebook_config.py /tmp/jupyter_notebook_config.py
