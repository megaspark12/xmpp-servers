# Openfire Application Deployment (Helm)

This repository contains a purpose-built Helm chart under `openfire/chart` that
deploys Openfire v5.0.2 in HA mode on the regional GKE cluster.

## Chart highlights

- **StatefulSet** with 3 replicas, persistent volumes, PodDisruptionBudget, and
  optional HPA.
- Pod init containers render `openfire.xml` from a ConfigMap (injecting the DB
  password) and download the Hazelcast clustering plugin.
- Sidecar **Cloud SQL Proxy** connects to the managed PostgreSQL instance over
  127.0.0.1 so no database credentials leave the pod.
- LoadBalancer service exposing all standard ports (5222/5269/7070/7443/9090/9091).

## Prerequisites

- `kubectl` context pointing at the regional GKE cluster
- Helm 3
- Terraform stack applied (from `infra/gcp`) so the Cloud SQL instance & service account exist
- Environment variables exported from unified Terraform outputs:

```bash
export OPENFIRE_DB_PASSWORD=$(terraform -chdir=infra/gcp output -raw openfire_sql_password)
export OPENFIRE_DB_CONN=$(terraform -chdir=infra/gcp output -raw openfire_sql_connection_name)
export OPENFIRE_GSA=$(terraform -chdir=infra/gcp output -raw openfire_cloudsql_service_account)
```

## Install / upgrade

```bash
cd openfire
helm upgrade --install openfire chart \
  --namespace openfire --create-namespace \
  --set-string database.password="$OPENFIRE_DB_PASSWORD" \
  --set-string database.connectionName="$OPENFIRE_DB_CONN" \
  --set-string serviceAccount.name="openfire" \
  --set-string serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account="$OPENFIRE_GSA" \
  --set-string openfire.domain="xmpp.example.internal"
```

Key value overrides:

- `serviceAccount.name=openfire` must match the IAM binding created by Terraform.
- `database.connectionName` ties the Cloud SQL Proxy to the right instance.
- `openfire.domain` controls what the admin console displays in URLs (optional).

## Validation commands

```bash
kubectl get pods -n openfire
kubectl get svc -n openfire
kubectl logs openfire-openfire-0 -n openfire openfire | tail
kubectl logs openfire-openfire-0 -n openfire cloud-sql-proxy | tail
```

Example outputs from the current deployment:

```bash
$ kubectl get pods -n openfire
NAME                  READY   STATUS    RESTARTS   AGE
openfire-openfire-0   2/2     Running   0          4m
openfire-openfire-1   2/2     Running   0          3m
openfire-openfire-2   2/2     Running   0          2m

$ kubectl get svc -n openfire
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)
openfire-openfire  LoadBalancer   10.40.x.x      35.x.x.x       5222/TCP ... 9091/TCP
```

The admin console sits behind the load balancer (for example
`http://<external-ip>:9090`; use HTTPS on 9091 if terminating TLS in Openfire). From your workstation you
can use the LB IP to access XMPP/S2S/BOSH. Pods reach the database through the
Cloud SQL Proxy, so no firewall updates are required.

## Ongoing operations

- Scale manually: `kubectl scale sts openfire-openfire -n openfire --replicas=5`
- Rotate DB password: run `terraform apply` to issue a new password, then redeploy
  Helm with the updated secret value (rolling update is automatic).
- Remove everything: `helm uninstall openfire -n openfire` followed by setting
  `enable_openfire_cloudsql=false` in `infra/gcp/terraform.tfvars` and
  running `terraform plan -out=tfplan && terraform apply tfplan` from `infra/gcp`.
