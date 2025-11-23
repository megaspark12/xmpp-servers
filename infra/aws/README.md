# xmpp Production Infrastructure on AWS

This Terraform stack mirrors the GCP design on AWS: a dedicated VPC with public/private subnets and NAT gateways, an EKS control plane spanning three AZs, a managed node group (one node per AZ by default), optional Multi-AZ RDS PostgreSQL instances for ejabberd/openfire, and an IRSA role for openfire when IAM DB auth is enabled. State stays local at `infra/aws/state/terraform.tfstate`.

## Prerequisites
- Terraform 1.5+
- AWS CLI v2 with credentials that can manage VPC, EKS, IAM, and RDS
- kubectl and Helm 3.14+
- Workstation IP/CIDR to restrict the EKS API endpoint

## Configure variables
```bash
cd infra/aws
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (region, cluster_name, availability_zones, api_allowed_cidrs, node_pool_* counts, node_instance_types)
# optional DB toggles: enable_ejabberd_rds / enable_openfire_rds and per-app sizing
```

## Provision
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Validation after apply:
- `aws eks describe-cluster --name <cluster_name> --region <region>`
- `aws eks update-kubeconfig --name <cluster_name> --region <region>`
- `kubectl get nodes -o wide` (expect one Ready node per AZ)
- If RDS enabled: `aws rds describe-db-instances --region <region>`

## Notes
- IRSA for openfire is created when both `enable_openfire_rds` and `enable_openfire_irsa` are true (IAM DB auth requires `openfire_rds_enable_iam_auth=true`).
- NAT gateways are provisioned per public subnet; adjust `public_subnet_cidrs`/`private_subnet_cidrs` to match your AZ selection.
- State remains local; no remote backend is configured.

## Troubleshooting
- Registry access issues during `terraform init`: retry once network/permissions allow HTTPS egress.
- Slow control-plane creation: re-run `terraform apply` after `aws eks describe-cluster` shows `ACTIVE`.
