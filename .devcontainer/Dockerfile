FROM python:3.11-buster

LABEL org.opencontainers.image.source=https://github.com/cal-itp/data-infra

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    USER=calitp

# install gcloud CLI
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update -y && apt-get install -y google-cloud-cli

# install pygraphviz deps
RUN apt-get update && apt-get install -y libgdal-dev libgraphviz-dev graphviz-dev

# create and switch to non-root user for devcontainer
RUN useradd --create-home --shell /bin/bash $USER && \
    chown -R $USER:$USER /home/$USER
USER $USER

# setup warehouse deps
WORKDIR /home/$USER/app/warehouse
# pip install location for non-root
ENV PATH="$PATH:/home/$USER/.local/bin"
# upgrade pip, install poetry
RUN python -m pip install --upgrade pip && pip install poetry

# copy source files
COPY ./warehouse/pyproject.toml pyproject.toml
COPY ./warehouse/poetry.lock poetry.lock
COPY ./warehouse/dbt_project.yml dbt_project.yml
COPY ./warehouse/packages.yml packages.yml

# install warehouse deps
RUN poetry install
RUN poetry run dbt deps

# install dev deps
RUN pip install black memray pre-commit

# switch back to app root
WORKDIR /home/$USER/app
# CMD for devcontainers
CMD ["sleep", "infinity"]
