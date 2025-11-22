#!/usr/bin/env bash
set -euo pipefail

OUT_FILE=${1:-cloudsql-values.generated.yaml}
TF_DIR="../infra/terraform"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi

echo "Reading Cloud SQL outputs from ${TF_DIR} ..."
SQL_HOST=$(terraform -chdir="${TF_DIR}" output -raw ejabberd_sql_host)
SQL_DB=$(terraform -chdir="${TF_DIR}" output -raw ejabberd_sql_database)
SQL_USER=$(terraform -chdir="${TF_DIR}" output -raw ejabberd_sql_username)
SQL_PASS=$(terraform -chdir="${TF_DIR}" output -raw ejabberd_sql_password)

cat > "${OUT_FILE}" <<EOF
sqlDatabase:
  enabled: true
  defaultDb: sql
  newSqlSchema: true
  updateSqlSchema: true
  config:
    sql_type: pgsql
    sql_server: ${SQL_HOST}
    sql_port: 5432
    sql_database: ${SQL_DB}
    sql_username: ${SQL_USER}
    sql_password: ${SQL_PASS}
modules:
  mod_mam:
    enabled: true
    options:
      assume_mam_usage: true
      default: always
      db_type: sql
  mod_offline:
    enabled: true
    options:
      access_max_user_messages: max_user_offline_messages
      db_type: sql
EOF

echo "Wrote ${OUT_FILE}."
echo "Apply with: helm upgrade --install ejabberd ejabberd/ejabberd -n ejabberd -f local-values.yaml -f ${OUT_FILE}"
