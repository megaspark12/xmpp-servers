# Production HA add-ons

This repo layer hardens the upstream chart for production HA. Changes in `local-values.yaml` disable HTTP admin exposure, enforce resource limits, pin a cluster cookie in a Secret, and add anti-affinity (host + zone preference). A PodDisruptionBudget is provided separately.

## Secrets
- Create a persistent Erlang cookie before installing/upgrading so nodes always rejoin the cluster:
  ```bash
  kubectl -n ejabberd create secret generic ejabberd-erlang-cookie \
    --from-literal=erlang-cookie="$(openssl rand -base64 32)"
  ```
- Keep the TLS and admin bootstrap secrets from `HELM_DEPLOYMENT.md` in place.

## Apply HA extras
- Apply the PDB to tolerate one voluntary disruption with a 3-replica cluster:
  ```bash
  kubectl apply -f ha-manifests/ejabberd-pdb.yaml
  ```
- Deploy/upgrade using the hardened values:
  ```bash
  helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd -f local-values.yaml
  ```

## Validation
- Sanity check the render locally:
  ```bash
  helm template --dry-run=client ejabberd ejabberd/ejabberd -f local-values.yaml >/tmp/ejabberd-render.yaml
  ```
- After deployment:
  - `kubectl -n ejabberd get pdb ejabberd` (expect `MIN AVAILABLE` 2).
  - `kubectl -n ejabberd get pods -o wide` (pods on distinct nodes).
  - `kubectl -n ejabberd get svc ejabberd` (only 5222/5443/5269 on TCP LB; admin HTTPS only).
  - Delete a pod or run `kubectl drain <node>` to confirm PDB enforcement and clean shutdown (`terminated` pods should log `ejabberdctl stop` and exit before the 90s grace period).

## Notes
- If you must expose HTTP admin temporarily, flip `listen.http.expose` back to `true`, but prefer HTTPS with Basic Auth.
- Adjust `ha-manifests/ejabberd-pdb.yaml` `minAvailable` when changing replica counts.
- For STUN client-IP preservation, consider `service.spec.externalTrafficPolicy: Local` and ensure one pod per node in the serving pool.

### Admin panel sanity check
- Map your LB IP to the primary host (e.g., `xmpp.local`) via DNS/hosts.
- Expect HTTPS admin on `https://<host>:5443/admin/` with Basic Auth using the admin user from your bootstrap secret.
- CLI check:
  ```bash
  curl -sk --resolve xmpp.local:5443:<TCP_LB_IP> \
    -u admin:'<PASSWORD>' \
    https://xmpp.local:5443/admin/ -o /tmp/ejadmin.html -w '%{http_code}\n'
  ```
  Expect `200`. If you need temporary HTTP access, set `listen.http.expose: true` and re-upgrade, then disable again.

## Cloud SQL (GCP) as the state backend
- Provision the DB via Terraform (private IP, regional, PITR enabled). Run `infra/terraform` first so the `network_name` exists:
  ```bash
  cd terraform/cloudsql
  cp terraform.tfvars.example terraform.tfvars
  # edit terraform.tfvars (project_id, region, optional network_name/private_service_cidr)

  terraform init
  terraform plan -out=tfplan
  terraform apply tfplan
  ```
  Key outputs: `sql_host`, `sql_database`, `sql_username`, `sql_password`, and `sql_connection_name`.
- Render a Helm overlay from Terraform outputs (kept out of git):
  ```bash
  ./scripts/render-cloudsql-values.sh cloudsql-values.generated.yaml
  ```
- Deploy using SQL:
  ```bash
  helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd \
    -f local-values.yaml \
    -f cloudsql-values.generated.yaml
  ```
- Post-deploy checks:
  - `kubectl -n ejabberd get pods -o wide` (all 3 Ready).
  - `kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status` and `list_cluster`.
  - `kubectl -n ejabberd logs ejabberd-0 | grep -i sql` (no connection errors).
  - `kubectl -n ejabberd get pdb ejabberd` (maxUnavailable: 1).
