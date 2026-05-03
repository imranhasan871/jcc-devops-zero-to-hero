{{/*
Expand the name of the chart.
*/}}
{{- define "jcc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated to 63 chars because Kubernetes name fields have this limit.
*/}}
{{- define "jcc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels applied to all resources in this chart.
These appear on every object so you can select them with kubectl.
*/}}
{{- define "jcc.labels" -}}
helm.sh/chart: {{ include "jcc.name" . }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "jcc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in matchLabels and pod template labels.
Must be stable across upgrades — changing these breaks rolling updates.
*/}}
{{- define "jcc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jcc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
