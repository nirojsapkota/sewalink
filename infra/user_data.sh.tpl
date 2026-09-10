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

cat > docker-compose.yml <<COMPOSE
services:
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: sewa_link
      POSTGRES_PASSWORD: ${db_password}
      POSTGRES_DB: sewa_link_production
    volumes:
      - pgdata:/var/lib/postgresql/data

  web:
    build: .
    restart: always
    env_file: .env
    depends_on:
      - db
    ports:
      - "80:3000"

volumes:
  pgdata:
COMPOSE

docker-compose up -d --build
