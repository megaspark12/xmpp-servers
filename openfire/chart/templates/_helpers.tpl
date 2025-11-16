{{/*
Expand the name of the chart.
*/}}
{{- define "openfire.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "openfire.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $fullname := printf "%s-%s" .Release.Name $name -}}
{{- if gt (len $fullname) 63 -}}
{{- printf "%s-%s" .Release.Name (trunc 63 $name | trimSuffix "-") -}}
{{- else -}}
{{- $fullname -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "openfire.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "openfire.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Service account name
*/}}
{{- define "openfire.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "openfire.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Checksum helpers used to trigger rolling upgrades
*/}}
{{- define "openfire.configChecksum" -}}
{{- include (print $.Template.BasePath "/configmap-openfirexml.yaml") . | sha256sum -}}
{{- end -}}

{{- define "openfire.secretChecksum" -}}
{{- if and (not .Values.database.existingSecret) .Values.database.password }}
{{- include (print $.Template.BasePath "/secret-database.yaml") . | sha256sum -}}
{{- else -}}
""
{{- end -}}
{{- end -}}
