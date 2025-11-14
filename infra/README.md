# xmpp Production Infrastructure on GCP

This directory contains the Terraform configuration that builds all cloud resources required to run the xmpp Helm chart on a highly-available Google Kubernetes Engine (GKE) regional cluster. The Terraform state intentionally stays local (`infra/terraform/state/terraform.tfstate`) so the entire workflow can be reproduced offline and audited before applying.

## Architecture

Terraform provisions the following components:

1. **Project services** – makes sure the Compute, Container, IAM, Logging, and Monitoring APIs are enabled before anything else.
2. **Networking** – a dedicated VPC, regional subnet, secondary IP ranges for pods/services, and Cloud NAT so private nodes can reach the internet for image pulls and updates.
3. **Regional GKE cluster** – the control plane lives in `europe-west1` and spans `europe-west1-b/c/d`, with Shielded Nodes, Workload Identity, VPC-native networking, and default cluster autoscaling disabled in favor of carefully managed node pools.
4. **Managed node pool** – Terraform manages a single primary pool spread across all three zones (one node per zone by default) with hardened metadata/access settings and a dedicated service account with only the permissions xmpp needs.
5. **Outputs** – helper commands (`gcloud container clusters get-credentials ...`) to plug the cluster into your MacBook once apply succeeds.

## Prerequisites

- Terraform 1.5+
- Google Cloud SDK (`gcloud`) 470+ with `kubectl` and `gke-gcloud-auth-plugin`
- Helm 3.14+
- A GCP project where you have at least `roles/owner` or the combination of `roles/container.admin`, `roles/compute.admin`, `roles/iam.serviceAccountAdmin`, `roles/resourcemanager.projectIamAdmin`, `roles/logging.admin`, and `roles/monitoring.admin`
- macOS workstation IP/CIDR block so the control plane can be locked down via master authorized networks
- Clone of this repository on your MacBook

## Authenticate and prepare the environment

1. Set your default project and authenticate:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project <your-project-id>
   ```
2. (Optional but recommended) Create a dedicated Terraform service account and key if you do not want to use your user credentials:
   ```bash
   gcloud iam service-accounts create tf-xmpp --display-name "Terraform for xmpp"
   gcloud projects add-iam-policy-binding <your-project-id> \
     --member="serviceAccount:tf-xmpp@<your-project-id>.iam.gserviceaccount.com" \
     --role="roles/owner"
   gcloud iam service-accounts keys create $HOME/.config/gcloud/tf-xmpp.json \
     --iam-account=tf-xmpp@<your-project-id>.iam.gserviceaccount.com
   export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/tf-xmpp.json
   ```
3. Capture your workstation IP (e.g., `curl ifconfig.me`) and convert it to CIDR notation (`x.x.x.x/32`). This will be used to secure the GKE control plane endpoint.

## Configure Terraform variables

1. Move into the Terraform directory and copy the example variable file:
   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars` with your details:
   - `project_id`, `region`, and `cluster_name`
   - `master_authorized_networks` to include your MacBook IP CIDR block(s)
   - Optional scaling tweaks such as `node_machine_type` or `node_pool_*` counts
3. (Optional) Commit the variable file to a secure secrets manager, not to git. `terraform.tfvars` is ignored by `.gitignore` on purpose.

## Provision the infrastructure with Terraform

1. Initialize providers and the local backend:
   ```bash
   terraform init
   ```
   Validation: `terraform providers` should list `hashicorp/google` and the `.terraform` directory should now exist locally.
2. Generate an execution plan:
   ```bash
   terraform plan -out=tfplan
   ```
   Validation: ensure the plan mentions only the expected GCP resources. If you see API enablement errors, wait ~60 seconds and re-run once the `google_project_service` resources finish propagating.
3. Apply the plan:
   ```bash
   terraform apply tfplan
   ```
   Validation steps after a successful apply:
   - `gcloud compute networks describe <network_name>` to confirm the subnet and secondary ranges.
   - `gcloud compute routers describe <cluster_name>-router --region <region>` to ensure Cloud NAT is online (the long-running `gcloud compute routers nats list` can be flaky; `describe` is more reliable).
   - `gcloud container clusters list --region <region>` should show the cluster in a `RUNNING` state and `MASTER_VERSION` pinned to the STABLE channel.

> Fixes along the way:
> - If `terraform init` complains about Terraform Core version, ensure the locally installed Terraform is >= 1.5.0 (we relaxed the constraint for the CLI runner).
> - If `terraform init` cannot reach registry.terraform.io, re-run with elevated permissions or a network path that allows HTTPS egress.
> - If `terraform plan` errors with `regexreplace` missing, make sure you have the latest repo code (we replaced that function with `replace/trim`).
> - If `terraform apply` times out while the cluster is still provisioning, double-check with `gcloud container clusters list`; if Terraform lost track of a partially-created cluster, delete the stray cluster (`gcloud container clusters delete xmpp-prod ...`) and rerun `terraform apply`.

## Example end-to-end deployment (2025‑11‑14 run)

Below is the exact sequence that provisioned the infrastructure from this repo. Update the placeholder values before rerunning the workflow.

```bash
# 1. Configure variables for the target project/region/cluster
cd infra/terraform
cat > terraform.tfvars <<'EOF'
project_id   = "<your-project-id>"
region       = "<your-region>"
cluster_name = "<cluster-name>"
node_pool_min_count = 3
node_pool_max_count = 6
master_authorized_networks = [] # or set your /32 workstation CIDR
EOF

# 2. Initialize providers/state and preview the work
terraform init
terraform plan -out=tfplan

# 3. Apply the plan (took ~15 minutes end-to-end)
terraform apply tfplan
```

Post-apply validations (run against the same project you targeted):

```bash
# Networking checks
gcloud compute networks describe <network_name> --project <project_id>
gcloud compute routers describe <cluster_name>-router --region <region> --project <project_id>

# Cluster + node pool checks
gcloud container clusters list --region <region> --project <project_id>
gcloud container node-pools list --cluster <cluster_name> --region <region> --project <project_id>
gcloud container node-pools describe <cluster_name>-pool --cluster <cluster_name> --region <region> --project <project_id>

# Pull kubeconfig and validate Kubernetes health
gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
kubectl cluster-info
kubectl get --raw='/readyz?verbose'
kubectl get nodes -o wide
kubectl get nodes -L topology.kubernetes.io/zone

# Confirm Terraform is tracking every resource
terraform state list
```

Observed results:
- `kubectl get nodes -L topology.kubernetes.io/zone` reported one Ready node in each zone (e.g., `region-a/b/c`), matching the high-availability goal.
- `kubectl get --raw='/readyz?verbose'` passed for all control-plane checks.
- `gcloud container node-pools describe <cluster_name>-pool ...` showed the expected machine type (`e2-standard-4`), `pd-balanced` disks, Shielded Nodes, Workload Identity, and autoscaling window (`min=3`, `max=6`).
- `terraform state list` contained the network, router, NAT, subnet, cluster, node pool, service account, IAM bindings, and API enablement resources, proving the deployment is fully reproducible from code.

## Connect from your MacBook and validate Kubernetes

1. Pull cluster credentials (exact command is also emitted as a Terraform output):
   ```bash
   gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
   ```
2. Confirm API reachability:
   ```bash
   kubectl cluster-info
   kubectl get nodes -o wide
   kubectl get --raw='/readyz?verbose'
   kubectl get nodes -L topology.kubernetes.io/zone
   ```
   Validation: three nodes (one per zone) should be `Ready` and show your custom labels/tags.
3. Inspect the node pool directly if needed:
   ```bash
   gcloud container node-pools describe <cluster_name>-pool --cluster <cluster_name> --region <region>
   ```

## Deploy the xmpp Helm chart

1. Update chart dependencies to ensure CRDs are pulled:
   ```bash
   helm dependency update chart/charts/xmpp
   ```
2. Provide a production values file (start from `chart/local-values.yaml` or your own) that includes image/tag information, persistent volume classes that exist on GKE, and external service annotations if needed.
3. Install/upgrade the release:
   ```bash
   helm upgrade --install xmpp chart/charts/xmpp \
     --namespace xmpp --create-namespace \
     -f chart/local-values.yaml
   ```
4. Validation commands:
   ```bash
   kubectl get pods -n xmpp -o wide
   kubectl get svc -n xmpp
   kubectl logs -n xmpp deployment/xmpp --tail=50
   kubectl exec -n xmpp deploy/xmpp -- xmppctl status
   ```
   Ensure the pods are spread across zones, services have ClusterIP/load balancers as expected, and `xmppctl status` reports a healthy cluster.

## Ongoing operations and observability checks

- Confirm Vertical Pod Autoscaler is active: `kubectl get vpa -A`
- Review events for scheduling pressure: `kubectl get events -A --sort-by=.lastTimestamp | tail`
- Pull control plane logs when debugging: `gcloud logging read "resource.type=k8s_cluster AND resource.labels.cluster_name=<cluster_name>" --limit 20`
- Validate NAT health: `gcloud compute routers nats describe <cluster_name>-nat --region <region>`

## Troubleshooting log

- 2025-11-14: `terraform init` failed due to strict required_version; updated to `>= 1.5.0, < 2.0.0`.
- 2025-11-14: `regexreplace` not supported by installed Terraform, replaced with `replace/trim` in `infra/terraform/iam.tf`.
- 2025-11-14: `terraform init` could not download providers from registry.terraform.io until run with elevated network permissions.
- 2025-11-14: First `terraform apply` timed out leaving an orphaned GKE cluster; deleted via `gcloud container clusters delete xmpp-prod --region europe-west1` and re-applied.
- 2025-11-14: GKE node pool briefly scaled to 9 nodes across MIG shards; to maintain predictable capacity we removed cluster autoscaling and explicitly set `initial_node_count` plus autoscaling min/max on the node pool, then recreated it.

## Cleanup

1. Remove the xmpp release:
   ```bash
   helm uninstall xmpp -n xmpp
   ```
   Validation: `kubectl get all -n xmpp` should return no resources.
2. Tear down the GCP infrastructure:
   ```bash
   cd infra/terraform
   terraform destroy
   ```
   Validation: `gcloud container clusters list --region <region>` and `gcloud compute networks list` should no longer show the cluster-specific resources.

With this workflow every step is documented, idempotent, and validated through `gcloud`, `kubectl`, and `helm` so you can repeatedly recreate the xmpp production platform from your MacBook.
