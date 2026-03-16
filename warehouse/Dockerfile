FROM  python:3.11-buster AS build

LABEL org.opencontainers.image.source=https://github.com/cal-itp/data-infra

RUN apt-get update
RUN apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update \
    && apt-get install -y nodejs libgdal-dev libgraphviz-dev graphviz-dev

RUN npm install -g --unsafe-perm=true --allow-root netlify-cli

ADD https://astral.sh/uv/0.10.9/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin:${PATH}"
ENV UV_NO_DEV=1

RUN mkdir /app
WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./uv.lock /app/uv.lock
COPY ./dbt_project.yml /app/dbt_project.yml
COPY ./packages.yml /app/packages.yml
COPY ./profiles.yml /app/profiles.yml

RUN uv sync
RUN uv run dbt deps
RUN uv pip install memray

COPY . /app

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
