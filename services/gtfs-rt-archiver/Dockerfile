FROM python:3.11-slim AS builder

# The installer requires curl (and certificates) to download the release archive
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates

# Download the latest installer
ADD https://astral.sh/uv/0.8.22/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

# Create and change to the app directory.
WORKDIR /usr/src/app

# Copy application dependency manifests to the container image and install
# dependencies.
COPY pyproject.toml uv.lock ./

# Disable development dependencies
ENV UV_NO_DEV=1

# Generate requirements.txt using uv
RUN uv export --no-hashes --format requirements-txt > requirements.txt

# Copy local code to the container image.
COPY . ./

# Install any dependencies of the function
RUN pip install -r requirements.txt

# Copy the source code and dependencies onto a scratch image.
FROM scratch
WORKDIR /workspace
COPY --from=builder --chown=33:33 /usr/src/app/ ./
USER 33:33

CMD ["functions-framework", "--target=handle_cloud_event", "--debug"]
