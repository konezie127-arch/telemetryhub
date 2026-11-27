#!/usr/bin/env bash
# Reconstruit l'infrastructure complete a partir des seuls fichiers du depot.
# Prerequis documentes : bucket d'etat (terraform/bootstrap), profil AWS, terraform.tfvars.
# Usage : scripts/rebuild.sh <image_tag>
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:?Usage: scripts/rebuild.sh <image_tag>}"
START=$SECONDS
LAST=$SECONDS
REPORT=()
mark() { REPORT+=("$(printf '%-36s %4ss' "$1" "$((SECONDS - LAST))")"); LAST=$SECONDS; }

echo "=== 1/5 Terraform : creation de l'infrastructure ==="
terraform -chdir=terraform init -input=false > /dev/null
terraform -chdir=terraform apply -auto-approve -input=false
mark "Terraform apply"

echo "=== 2/5 Generation de l'inventaire Ansible ==="
./scripts/gen_inventory.sh
mark "Generation de l'inventaire"

echo "=== 3/5 Attente de l'instance (SSH) ==="
cd ansible
for i in $(seq 1 30); do
  if ansible -i inventory.ini app -m ping > /dev/null 2>&1; then break; fi
  echo "  tentative $i : instance pas encore joignable"
  sleep 10
done
ansible -i inventory.ini app -m ping
mark "Attente de l'instance (SSH)"

echo "=== 4/5 Ansible : Docker et application ==="
ansible-playbook -i inventory.ini site.yml -e image_tag="$TAG"
mark "Ansible (Docker + application)"
cd ..

echo "=== 5/5 Verification de bout en bout ==="
IP="$(terraform -chdir=terraform output -raw public_ip)"
OK=0
for i in $(seq 1 15); do
  if curl -fsS --max-time 5 "http://$IP/version" | grep -q "\"git_sha\":\"$TAG\""; then OK=1; break; fi
  sleep 4
done
mark "Verification HTTP"
[ "$OK" = "1" ] || { echo "ECHEC : la version $TAG n'est pas en ligne" >&2; exit 1; }

echo
echo "=============== RAPPORT ==============="
printf '%s\n' "${REPORT[@]}"
printf '%-36s %4ss\n' "TOTAL" "$((SECONDS - START))"
echo "URL : http://$IP"
curl -fsS "http://$IP/version"; echo
