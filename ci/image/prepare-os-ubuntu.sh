#!/bin/bash
set -e

pkgs=(
 google-cloud-sdk
 docker-ce-cli
)

# Baseline

apt-get update
apt-get -y install apt-transport-https ca-certificates gnupg curl


# repo: google-cloud-sdk
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
cat <<EOF > /etc/apt/sources.list.d/google-cloud-sdk.list
deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main
EOF


# repo: docker-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
cat <<EOF > /etc/apt/sources.list.d/docker-ce.list
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2-) stable
EOF

# CI Environment

apt-get update
apt-get -y install "${pkgs[@]}"
