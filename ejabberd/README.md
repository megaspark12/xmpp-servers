# Deploy ejabberd on Kubernetes (HA)

This repo contains a hardened Helm chart for ejabberd. Use `values.yaml` for HA defaults (3 replicas, anti-affinity, 10Gi PVCs, 90s termination grace, pinned cluster cookie, HTTPS admin only). The chart ships with the built-in Mnesia database; use the Cloud SQL steps below to switch to managed PostgreSQL.

## Prerequisites (one time)

```bash
cd ejabberd
kubectl create namespace ejabberd

# TLS + admin bootstrap (example self-signed)
tmpdir=$(mktemp -d)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=xmpp.local" \
  -keyout "$tmpdir/ejabberd.key" \
  -out "$tmpdir/ejabberd.crt"
cat "$tmpdir/ejabberd.crt" "$tmpdir/ejabberd.key" > "$tmpdir/ejabberd.pem"
kubectl -n ejabberd create secret generic ejabberd-local-cert \
  --type kubernetes.io/tls \
  --from-file=tls.crt="$tmpdir/ejabberd.crt" \
  --from-file=tls.key="$tmpdir/ejabberd.key" \
  --from-file=ejabberd.pem="$tmpdir/ejabberd.pem"
kubectl -n ejabberd create secret generic ejabberd-admin-bootstrap \
  --from-literal=ctl_on_create="ejabberdctl register admin xmpp.local <STRONG_PASSWORD>"
rm -rf "$tmpdir"

# persistent Erlang cookie so nodes always rejoin
kubectl -n ejabberd create secret generic ejabberd-erlang-cookie \
  --from-literal=erlang-cookie="$(openssl rand -base64 32)"
```

## Deploy / upgrade

```bash
# optional render check
helm template --dry-run=client ejabberd ejabberd/ejabberd -f values.yaml >/tmp/ejabberd-render.yaml

# install/upgrade
helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd -f values.yaml

# optional PDB (allows 1 pod down in a 3-node cluster)
kubectl apply -f ha-manifests/ejabberd-pdb.yaml
```

## Validate

- `kubectl -n ejabberd rollout status statefulset/ejabberd`
- `kubectl -n ejabberd get pods -o wide` (spread across nodes/zones)
- `kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status` and `list_cluster`
- `kubectl -n ejabberd get svc ejabberd` (LB IPs present; ports 5222/5443/5269)
- `kubectl -n ejabberd get pdb ejabberd` (MIN AVAILABLE 2 / maxUnavailable 1)
- Drain a node or delete a pod; expect graceful stop within 90s and cluster stays healthy.

## Admin panel check

Map LB IP to your host (e.g., `xmpp.local`) then:

```bash
curl -sk --resolve xmpp.local:5443:<TCP_LB_IP> \
  -u admin:'<PASSWORD>' \
  https://xmpp.local:5443/admin/ -o /tmp/ejadmin.html -w '%{http_code}\n'
```

Expect `200`. If you must temporarily expose HTTP admin, set `listen.http.expose: true` in `values.yaml`, upgrade, then revert.

## Cloud SQL (GCP) backend

To replace the default Mnesia database with managed PostgreSQL:

1) Enable the ejabberd Cloud SQL module in Terraform (private IP + PITR by default):

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (project_id, region, master_authorized_networks, etc.)
# set enable_ejabberd_cloudsql=true (plus cloudsql_use_private_ip/cloudsql_create_psa as needed)

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

2) Generate the Helm overlay from Terraform outputs (script reads state from `infra/terraform` and writes SQL creds into the values file):

```bash
cd ejabberd
./scripts/render-cloudsql-values.sh cloudsql-values.generated.yaml
```

3) Install/upgrade the release with the Cloud SQL overlay:

```bash
helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd \
  -f values.yaml \
  -f cloudsql-values.generated.yaml
```

4) Validate SQL is active (no `mnesia` fallbacks):
- `kubectl -n ejabberd get pods -o wide` (all Ready)
- `kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status` and `list_cluster`
- `kubectl -n ejabberd logs ejabberd-0 | grep -i 'sql_'` (no errors)
- `kubectl -n ejabberd get pdb ejabberd` (PDB honored)
