#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker git

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# dnf's Docker package ships an old buildx (v0.12.x) that's too old for
# `docker-compose build` (needs 0.17+). Replace it with a current release.
BUILDX_VERSION="v0.19.3"
ARCH="$(uname -m)"
if [ "$ARCH" = "aarch64" ]; then BUILDX_ARCH="arm64"; else BUILDX_ARCH="amd64"; fi
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL "https://github.com/docker/buildx/releases/download/$${BUILDX_VERSION}/buildx-$${BUILDX_VERSION}.linux-$${BUILDX_ARCH}" \
  -o /usr/libexec/docker/cli-plugins/docker-buildx
chmod +x /usr/libexec/docker/cli-plugins/docker-buildx

# t4g.micro only has 1GB RAM, which isn't enough for `bundle install` (native
# extension compilation) during the Docker build. Add swap to avoid OOM kills.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

mkdir -p /opt/app
cd /opt/app

%{ if github_pat != "" }
git clone "https://${github_pat}@github.com/${github_repo}.git" . || (git pull)
%{ else }
git clone "https://github.com/${github_repo}.git" . || (git pull)
%{ endif }

cat > .env <<ENV
RAILS_ENV=production
RAILS_MASTER_KEY=${rails_master_key}
SEWA_LINK_DATABASE_PASSWORD=${db_password}
DATABASE_URL=postgresql://sewa_link:${db_password}@db:5432/sewa_link_production
ENV

# docker-compose.yml is now a static, version-controlled file checked into the
# repo (see /docker-compose.yml). docker-compose auto-loads .env from this same
# directory for $${VAR} interpolation, so no need to regenerate the compose file here.

# The web container writes to log/production.log as a non-root user (rails).
# The bind-mounted host dir is created by this root-owned git clone, so make
# it writable before the container starts.
mkdir -p log
chmod 777 log

docker-compose up -d --build
