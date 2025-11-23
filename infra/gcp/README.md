# xmpp Production Infrastructure on GCP

This Terraform stack builds the GKE-based production footprint for xmpp: a dedicated VPC with secondary ranges, regional GKE control plane spanning three zones, a managed node pool (one node per zone by default), and optional regional Cloud SQL PostgreSQL instances for ejabberd/openfire. Terraform state stays local at `infra/gcp/state/terraform.tfstate` so the workflow can be audited offline.

## Architecture
1. **Project services** – enables Compute, Container, IAM, Logging, and Monitoring APIs.
2. **Networking** – custom VPC, regional subnet, pod/service secondary ranges, and Cloud NAT for private nodes.
3. **Regional GKE cluster** – Shielded Nodes, Workload Identity, VPC-native networking, release channel pinning, and controlled autoscaling via the managed pool.
4. **Managed node pool** – spread across the three AZs in the region, hardened metadata/access, dedicated service account with minimal roles.
5. **Outputs** – helper commands (`gcloud container clusters get-credentials ...`) to plug the cluster into your workstation.
6. **(Optional) Cloud SQL** – regional PostgreSQL (private IP via PSA) for ejabberd/openfire, DB/user credentials, and Workload Identity SA for openfire.

## Prerequisites
- Terraform 1.5+
- Google Cloud SDK (`gcloud`) 470+ with `kubectl` and `gke-gcloud-auth-plugin`
- Helm 3.14+
- A GCP project with permissions to manage GKE/Compute/IAM/Logging/Monitoring
- Your workstation IP/CIDR (for master authorized networks)

## Configure variables
```bash
cd infra/gcp
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (project_id, region, cluster_name, master_authorized_networks, etc.)
# optional: enable_ejabberd_cloudsql / enable_openfire_cloudsql and PSA settings
```

## Provision
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Validation after apply:
- `gcloud compute networks describe <network_name>`
- `gcloud compute routers describe <cluster_name>-router --region <region>`
- `gcloud container clusters list --region <region>`
- `gcloud container clusters get-credentials <cluster_name> --region <region>`
- `kubectl get nodes -o wide` (expect one Ready node per zone)

## Example end-to-end (template)
```bash
cd infra/gcp
cat > terraform.tfvars <<'EOF'
project_id   = "<your-project-id>"
region       = "<your-region>"
cluster_name = "<cluster-name>"
node_pool_min_count = 3
node_pool_max_count = 6
master_authorized_networks = [] # or your /32 workstation CIDR
# enable_ejabberd_cloudsql = true
# enable_openfire_cloudsql = true
# cloudsql_use_private_ip  = true
# cloudsql_create_psa      = true
# cloudsql_psa_cidr        = "10.60.0.0/24"
EOF

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Troubleshooting
- `terraform init` version complaints: ensure Terraform >= 1.5.0.
- API enablement errors: re-run plan after ~60s for `google_project_service` to propagate.
- Long cluster creates: `gcloud container clusters list --region <region>` to confirm status; delete strays before re-applying.
