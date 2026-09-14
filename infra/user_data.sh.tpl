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

docker-compose up -d --build
