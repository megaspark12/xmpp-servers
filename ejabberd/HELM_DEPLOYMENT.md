# ejabberd HA Deployment Notes (GKE)

This captures the working steps used to deploy the ejabberd Helm chart onto the
`chkp-gcp-prd-kenobi-box` regional GKE cluster and validate availability,
scalability, and external access from macOS.

## 1. Prepare overrides

`chart/local-values.yaml` contains the production overrides used during the GKE
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

## 2. Bootstrap namespace and TLS secret

```bash
kubectl create namespace ejabberd

tmpdir=$(mktemp -d)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=xmpp.local" \
  -keyout "$tmpdir/ejabberd.key" \
  -out "$tmpdir/ejabberd.crt"
kubectl -n ejabberd create secret tls ejabberd-local-cert \
  --cert="$tmpdir/ejabberd.crt" \
  --key="$tmpdir/ejabberd.key"
rm -rf "$tmpdir"
```

Replace the OpenSSL block with the workflow that issues your production
certificate; the secret name must stay in sync with
`.Values.certFiles.secretName`.

## 3. Install / upgrade the release

```bash
helm dependency update chart/charts/ejabberd
helm upgrade --install ejabberd chart/charts/ejabberd \
  -n ejabberd \
  -f chart/local-values.yaml
```

The deploy on 2025‑11‑14 finished with `revision: 2` and issued one TCP Load
Balancer (`146.148.113.87`) and one UDP Load Balancer (`146.148.122.162`).

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

- `ejabberd` (TCP) external IP: **146.148.113.87**
- `ejabberd-udp` external IP: **146.148.122.162**

From the macOS workstation, map `xmpp.local` to the TCP IP (or create a proper
DNS record) and confirm reachability:

```bash
# macOS /etc/hosts entry
echo "146.148.113.87 xmpp.local" | sudo tee -a /etc/hosts

# Connectivity tests
nc -vz 146.148.113.87 5222   # jabber-client
nc -vz 146.148.113.87 5443   # https interface
```

For UDP/STUN, point clients to `146.148.122.162:3478`.

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
