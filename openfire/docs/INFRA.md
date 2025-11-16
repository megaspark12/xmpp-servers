# Openfire Infrastructure (Terraform)

This document covers the "as-code" infrastructure that Openfire requires inside
GCP. All code lives under `openfire/terraform` and is independent from the global
`infra/` stack that builds the regional GKE cluster.

## What Terraform creates

- **Cloud SQL for PostgreSQL** (regional, `db-custom-2-8192`, SSD, PITR enabled)
- **Logical database + user** dedicated to Openfire with a randomly generated password
- **Service account** (`openfire-sql-client@…`) and IAM bindings:
  - `roles/cloudsql.client`
  - `roles/cloudsql.instanceUser`
  - `roles/iam.workloadIdentityUser` for the Kubernetes service account `openfire/openfire`

> Note: The cluster was built without Service Networking / private IP peering for
> Cloud SQL, so this stack enables **public IPv4** on the instance and expects
> every workload to use the Cloud SQL Proxy sidecar.

## Prerequisites

- Terraform ≥ 1.5
- Authenticated `gcloud` CLI pointing at the correct project
- Access to the regional GKE cluster created by `infra/`
- `terraform.tfvars` with at least `project_id` and `region` set (see example below)

```hcl
project_id = "<your-gcp-project-id>"
region     = "europe-west1"
# optional overrides
#gcp_service_account_id = "openfire-sql-client"
#ksa_namespace          = "openfire"
#ksa_name               = "openfire"
```

## Workflow

```bash
cd openfire/terraform
terraform init
terraform plan
terraform apply
```

Terraform keeps state in `openfire/terraform/state/terraform.tfstate`, so the
stack is reproducible offline. On apply it prints all outputs, for example:

```bash
$ terraform -chdir=openfire/terraform output -json
{
  "openfire_db_connection_name": "<project:region:instance>",
  "openfire_db_name": "openfire",
  "openfire_db_user": "openfire_app",
  "openfire_db_password": "<sensitive>",
  "openfire_cloud_sql_sa": "openfire-sql-client@<project>.iam.gserviceaccount.com"
}
```

Use these outputs when deploying the Helm chart.

## Validation performed

- `terraform -chdir=openfire/terraform plan` and `apply` (providers fetched with
  elevated permissions because registry.terraform.io is blocked in the default sandbox)
- `gcloud sql instances describe openfire-sql --project <your-gcp-project>`
  (confirmed IPv4 enabled + regional HA)
- `gcloud iam service-accounts get-iam-policy openfire-sql-client@<project>.iam.gserviceaccount.com` to verify the
  Workload Identity binding for `openfire/openfire`

## Clean-up

To destroy only the Openfire-specific resources (without touching the cluster):

```bash
cd openfire/terraform
terraform destroy
```

Because deletion protection is disabled, the Cloud SQL instance and service
account will be removed. Delete the Helm release first to avoid dangling pods.
