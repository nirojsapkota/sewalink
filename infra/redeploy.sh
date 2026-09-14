#!/bin/bash
# Redeploy latest app code to the already-running EC2 instance, without
# touching Terraform-managed infrastructure.
set -euo pipefail

IP=$(terraform output -raw public_ip)
KEY="sewalink-deployer.pem"

ssh -o StrictHostKeyChecking=no -i "$KEY" "ec2-user@$IP" '
  cd /opt/app &&
  sudo git pull &&
  sudo docker-compose up -d --build
'

echo "Deployed. Check: http://$IP"
