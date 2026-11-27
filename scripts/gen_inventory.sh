#!/usr/bin/env bash
set -euo pipefail

IP=$(terraform -chdir=terraform output -raw public_ip)

cat > ansible/inventory.ini <<EOF
[app]
telemetryhub ansible_host=${IP}

[app:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/telemetryhub-tf
EOF

echo "Inventaire généré pour ${IP}"
