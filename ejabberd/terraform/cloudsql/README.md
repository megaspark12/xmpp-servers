# ejabberd Cloud SQL (GCP)

This Terraform stack provisions a private PostgreSQL Cloud SQL instance for ejabberd inside the shared xmpp VPC created by `infra/terraform`.

## What it builds
- Enables the Service Networking + Cloud SQL Admin APIs (project-local).
- Reserves a Private Service Access range inside the shared VPC and peers it.
- Creates a regional PostgreSQL instance (private IP only) with PITR + backups.
- Creates a logical database, user, and random password for ejabberd.

## Prerequisites
- Run `infra/terraform` first so the `xmpp-prod-net` VPC exists (or set `network_name` to match your deployment).
- Terraform 1.5+, Google Cloud SDK authenticated against the target project.
- Non-overlapping CIDR for `private_service_cidr` (defaults to `10.60.0.0/24`).

## Usage
```bash
cd terraform/cloudsql
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your project_id/region (and network_name if different)

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Key outputs (also consumed by `scripts/render-cloudsql-values.sh`):
- `sql_host` – private IP for the instance.
- `sql_database`, `sql_username`, `sql_password` – credentials for ejabberd.
- `sql_connection_name` – for Cloud SQL Auth Proxy if you choose to run it.

## Validation
- Confirm the peering exists: `gcloud services vpc-peerings list --network=<network_name> --project <project_id>`.
- Describe the instance and verify it reports a private IP and `REGIONAL` availability:  
  `gcloud sql instances describe <db_instance_name> --project <project_id>`.
- Generate the Helm overlay and dry-run the render:  
  `./scripts/render-cloudsql-values.sh /tmp/cloudsql-values.yaml`  
  `helm template --dry-run=client ejabberd ejabberd/ejabberd -f local-values.yaml -f /tmp/cloudsql-values.yaml >/tmp/ejabberd-render.yaml`
