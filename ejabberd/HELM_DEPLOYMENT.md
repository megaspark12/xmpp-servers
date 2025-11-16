# ejabberd HA Deployment Notes (GKE)

This captures the working steps used to deploy the ejabberd Helm chart onto a
regional GKE cluster and validate availability,
scalability, and external access from macOS.

## Repository layout

```
.
├── HELM_DEPLOYMENT.md
├── README.md
└── local-values.yaml
```

## 1. Prepare overrides

`local-values.yaml` contains the production overrides used during the GKE
deployment:

```yaml
hosts:
  - xmpp.local

certFiles:
  secretName:
    - ejabberd-local-cert

statefulSet:
  replicas: 3

service:
  single: false       # separate TCP + UDP load balancers (GKE limitation)
  type: LoadBalancer
  spec:
    externalTrafficPolicy: Cluster

persistence:
  enabled: true
  storageClass: standard-rwo
  accessModes:
    - ReadWriteOnce
  size: 10Gi

resources:
  requests:
    cpu: 500m
    memory: 1Gi
```

This keeps three replicas online, provisions 10 Gi persistent volumes per pod,
requests reasonable baseline resources, and exposes TCP (5222/5269/5443) and UDP
(3478) services through dedicated Google Cloud Load Balancers.

> **API permissions requirement:** The startup/readiness script calls
> `http://127.0.0.1:5281/api/status`. Keep the default `apiPermissions`
> definitions (`admin access`, `console commands`, `public commands`) alongside
> the custom `webadmin commands` override in `local-values.yaml`; otherwise those
> probes fail and pods remain stuck in `ContainerCreating`.

## 2. Bootstrap namespace and TLS secret

```bash
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
rm -rf "$tmpdir"
```

Replace the OpenSSL block with the workflow that issues your production
certificate; the secret name must stay in sync with
`.Values.certFiles.secretName`.

> **Why `ejabberd.pem`?** The chart mounts `/opt/ejabberd/certs/<secret>/` and
> expects at least one `*.pem` bundle (cert + key). Adding `ejabberd.pem`
> ensures the HTTPS admin listener (5443/tcp) can successfully present a
> certificate.

## 3. Install / upgrade the release

```bash
cd ejabberd
helm repo add ejabberd https://sando38.github.io/helm-ejabberd
helm repo update
helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd -f local-values.yaml
```

The chart is now sourced from the hosted Helm repository, so the `helm repo add`
step only needs to be run once per environment; subsequent deploys can reuse the
registered repo after calling `helm repo update`.

The deploy on 2025‑11‑16 finished with `revision: 1` and issued one TCP Load
Balancer (`<TCP_LB_IP>`) and one UDP Load Balancer (`<UDP_LB_IP>`).

## 4. Validate HA + scaling

```bash
kubectl -n ejabberd rollout status statefulset/ejabberd
kubectl -n ejabberd get pods -o wide
kubectl -n ejabberd get pvc
kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl status
kubectl -n ejabberd exec ejabberd-0 -- ejabberdctl list_cluster
```

Observed results:

- Three pods scheduled across distinct nodes / zones
  (`europe-west1-b/c/d`). Each pod owns a bound `standard-rwo` PVC.
- `ejabberdctl list_cluster` shows all three Erlang nodes joined.
- Node-level HA supplied by the regional node pool (autoscaling 3‑6 nodes).

## 5. Validate load balancers & connectivity

```bash
kubectl -n ejabberd get svc ejabberd
kubectl -n ejabberd get svc ejabberd-udp
```

At the time of deployment:

- `ejabberd` (TCP) external IP: **<TCP_LB_IP>**
- `ejabberd-udp` external IP: **<UDP_LB_IP>**

From the macOS workstation, map `xmpp.local` to the TCP IP (or create a proper
DNS record) and confirm reachability:

```bash
# macOS /etc/hosts entry
echo "<TCP_LB_IP> xmpp.local" | sudo tee -a /etc/hosts

# Connectivity tests
nc -vz <TCP_LB_IP> 5222   # jabber-client
nc -vz <TCP_LB_IP> 5443   # https interface
```

For UDP/STUN, point clients to `<UDP_LB_IP>:3478`.

## 6. Optional functional checks

```bash
kubectl -n ejabberd exec ejabberd-0 -- \
  ejabberdctl register demo xmpp.local demoPass123
kubectl -n ejabberd exec ejabberd-0 -- \
  ejabberdctl status
kubectl -n ejabberd exec ejabberd-0 -- \
  ejabberdctl connected_users
```

Use any XMPP client (e.g., Gajim) on macOS, point it at `xmpp.local`, port 5222,
enable TLS, and authenticate with the test user to perform an end-to-end check.

## 7. Web admin & HTTP API

`local-values.yaml` exposes the admin UI on both HTTP (5280/tcp) and HTTPS
(5443/tcp) and grants admin access to the `admin@xmpp.local` account.

1. Create the admin user (rotate the password prior to production hardening),
   for example:

   ```bash
   kubectl -n ejabberd exec ejabberd-0 -- \
     ejabberdctl register admin xmpp.local '<STRONG_PASSWORD>'
   ```

2. Map the load balancer IP to `xmpp.local` (see section 5) and confirm both
   listeners are enforcing HTTP Basic Auth. Examples from this deployment:

   ```bash
   # Expect 401 without credentials
   curl -I http://<TCP_LB_IP>:5280/admin/

   # HTTPS check with TLS + credentials (returns HTTP 200)
   curl -sk --resolve xmpp.local:5443:<TCP_LB_IP> \
     -u admin:'<STRONG_PASSWORD>' \
     https://xmpp.local:5443/admin/ \
     -o /tmp/ejadmin.html -w '%{http_code}\n'
   ```

3. Browse to `https://xmpp.local:5443/admin/`, accept the self-signed cert, and
   sign in with the admin credentials to manage users, nodes, and connected
   clients. The HTTPS listener now succeeds because the TLS secret contains the
   concatenated `ejabberd.pem` bundle described in section 2.

4. Invoke HTTP API endpoints with the same credentials. The readiness probes and
   manual `curl` checks use `https://xmpp.local:5443/api/status`, so keeping the
   Basic Auth credentials handy (or storing them in a Kubernetes secret) is
   essential for automation and monitoring.
