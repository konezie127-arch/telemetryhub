# Runbook

## Prerequis (uniques, hors reconstruction)

1. Compte AWS, utilisateur IAM avec profil local `telemetryhub`.
2. Bucket d'etat cree par `terraform/bootstrap` (`terraform init` puis `apply` dans ce dossier).
3. `terraform/terraform.tfvars` (ignore par Git) avec `ssh_allowed_cidr` = IP publique de l'administrateur en /32.
4. Variable GitHub `AWS_DEPLOY_ROLE_ARN`.
5. Cle SSH `~/.ssh/telemetryhub-tf`.

## Reconstruire toute l'infrastructure

```bash
export AWS_PROFILE=telemetryhub
terraform -chdir=terraform destroy      # optionnel : repartir de zero
scripts/rebuild.sh <sha_court_de_l_image>
```
Duree mesuree : environ 2 min 40 s, sans intervention manuelle.

## Incidents rencontres et resolution

| Symptome | Cause | Resolution |
|---|---|---|
| SSH ou Ansible : `Connection timed out` | L'IP publique de l'administrateur a change | Mettre a jour `ssh_allowed_cidr`, puis `terraform apply` |
| `Error acquiring the state lock` | Autre `terraform` en cours, ou verrou orphelin | Verifier `pgrep -a terraform`, puis `terraform force-unlock <ID>` |
| `Could not load credentials` dans le pipeline | Variable absente ou creee comme secret | La creer dans l'onglet **Variables** |
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | `sub` OIDC different : GitHub utilise des identifiants immuables | Utiliser le prefixe fourni par l'API de personnalisation du `sub` |
| `Un deploiement est deja en cours` | Verrou `flock` : deploiement concurrent | Attendre la fin du premier |
| Deploiement en echec avec rollback reussi | Version defaillante en production | Corriger, ou `git revert` du commit fautif |
