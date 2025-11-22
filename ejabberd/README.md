# helm chart for ejabberd

This repository holds a helm chart for [ejabberd](https://github.com/processone/ejabberd)
which
> [...] is an open-source, robust, scalable and extensible realtime platform
> built using Erlang/OTP, that includes XMPP Server, MQTT Broker and SIP Service.

The chart configures the environment needed to build and run ejabberd kubernetes
clusters. Additionally, the `values.yaml` file allows to include most of the
configuration items, ejabberd offers in their [`ejabberd.yml`](https://github.com/processone/ejabberd/blob/master/ejabberd.yml.example).

The chart and its items can be found [here](charts/ejabberd).

## Current state

The chart is under development, meaning there is room for enhancements and
improvements. The [issue tracker](https://github.com/sando38/helm-ejabberd/issues)
may be used to define roadmap items.

The chart is functional and needs testing. Please report back if anything does
not work as expected.

This repository also contains a CI which tests basic activities, e.g. scaling,
XMPP connectivity and traffic with [processone's rtb](https://github.com/processone/rtb)
as well as pod failures, kills, etc. with [chaos mesh](https://chaos-mesh.org/).

Contributors and PRs are also welcome.

## Base image

The chart uses a custom ejabberd image, which is based on the [official](https://github.com/processone/ejabberd/blob/master/CONTAINER.md)
ejabberd container image.

The image name is: `ghcr.io/sando38/helm-ejabberd:24.12-k8s1`

### Difference to the official ejabberd container image

This repository contains the patches applied to the official ejabberd [releases](https://github.com/processone/ejabberd/releases)
in the [image](image) directory and the respective [workflow file](.github/workflows/ctr.yaml).

A short summary:

* Redesigned image based on [Wolfi-OS](https://github.com/wolfi-dev/os) to
  significantly improve the performance and resource usage.
* Includes an elector service to create kubernetes `leases` for pod leaders.
* Includes custom scripts to automatically detect and join a cluster as well as
  for performing healthchecks and self-healing.
* Slighlty modified `ejabberdctl` to use correct naming conventions for
  ejabberd clusters in kubernetes.
* Stipped/ hardened image by deleting all unneccessary packages from the image,
  e.g. package managers, etc.
* Includes additional libraries for ejabberd contribution modules
  `ejabberd_auth_http` and `mod_ecaptcha`.
* The three mentioned modules plus `mod_s3_upload` are installed in the image
  already.
* No ACME support, mounting your certs as k8s secrets is necessary.
* No support for CAPTCHA scripts, due to the nature of the stripped image.

### Image tags

The patches are defined per release, hence a container image tag always bears
the ejabberd release, e.g.: `24.12`.

Furthermore, a suffix `-k8s1` is used in case the image needs an update. The
first release image has a suffix `-k8s1`.

### Running this image with docker compose

The image may be used with `docker compose` using the following definitions:

```yml
version: '3'

services:
  ejabberd:
    image: ghcr.io/sando38/helm-ejabberd:24.12-k8s1
    command: >
      sh -c "ejabberdctl foreground"
    environment:
      - ERLANG_NODE_ARG=ejabberd@localhost
```

## GKE Deployment Notes (HA)

```bash
cd ejabberd
# prepare namespace and TLS/admin secrets (example self-signed)
kubectl create namespace ejabberd
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

# deploy (local-values.yaml contains HA overrides)
helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd -f local-values.yaml
```

Key HA settings (from `local-values.yaml`):
- 3 replicas, 10Gi RWO PVCs, anti-affinity, 90s termination grace
- TCP/UDP LBs (GKE limitation on shared protocols)
- Resources: requests 500m/1Gi, limits 1500m/2Gi
- HTTP admin disabled by default (`listen.http.expose: false`); HTTPS admin on 5443

Validation:
- `kubectl -n ejabberd rollout status statefulset/ejabberd`
- `kubectl -n ejabberd get pods -o wide` (spread across zones)
- `kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status` and `list_cluster`
- `kubectl -n ejabberd get svc ejabberd` (LB IPs present)

Optional PDB:
```bash
kubectl apply -f ha-manifests/ejabberd-pdb.yaml
```

## Cloud SQL (GCP) as the state backend

Provision via unified Terraform (private IP, regional, PITR enabled):
```bash
cd infra/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
- Set `enable_ejabberd_cloudsql=true` in `infra/terraform/terraform.tfvars` before planning/applying.
- Key outputs: `ejabberd_sql_host`, `ejabberd_sql_database`, `ejabberd_sql_username`, `ejabberd_sql_password`, `ejabberd_sql_connection_name`.

Render Helm overlay from Terraform outputs:
```bash
cd ejabberd
./scripts/render-cloudsql-values.sh cloudsql-values.generated.yaml
helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd \
  -f local-values.yaml \
  -f cloudsql-values.generated.yaml
```

Post-deploy checks (SQL):
- `kubectl -n ejabberd get pods -o wide` (all Ready)
- `kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status` and `list_cluster`
- `kubectl -n ejabberd logs ejabberd-0 | grep -i sql` (no errors)
- `kubectl -n ejabberd get pdb ejabberd` (PDB honored)

Note: `command` and `environment` arguments are required to simulate the
official image behhavior.

## Merging the chart upstream

Yes, that is considered and actually also desired ([link to discussion](https://github.com/processone/ejabberd/discussions/4065)).
