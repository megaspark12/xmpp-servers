# xmpp Production Infrastructure

Platform-specific Terraform stacks now live in dedicated folders:

- `infra/gcp` – GKE + Cloud SQL
- `infra/aws` – EKS + RDS

Each folder contains its own `README.md` with prerequisites, variables, and provisioning steps. State remains local to each stack (see the platform README for paths).

## Troubleshooting log

- 2025-11-14: `terraform init` failed due to strict required_version; updated to `>= 1.5.0, < 2.0.0`.
- 2025-11-14: `regexreplace` not supported by installed Terraform, replaced with `replace/trim` in `infra/gcp/iam.tf`.
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
   cd infra/gcp
   terraform destroy
   ```
   Validation: `gcloud container clusters list --region <region>` and `gcloud compute networks list` should no longer show the cluster-specific resources.
   For AWS, run `terraform destroy` from `infra/aws`.

With this workflow every step is documented, idempotent, and validated through `gcloud`, `kubectl`, and `helm` so you can repeatedly recreate the xmpp production platform from your MacBook.
