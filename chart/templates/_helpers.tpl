{{- /*
The names every component shares, each written once here and reached through these helpers, never
typed in a component's template (chart-and-policy.md; charttest.CheckSources refuses one written
elsewhere). Each takes the chart's root context: alone as ".", or first in a list beside the part it
renders, (list . "volume") or (list . "mount").
*/ -}}

{{- /* v2b.archive.port: the archive's container port, named api, as one item of a container's ports. */ -}}
{{- define "v2b.archive.port" -}}
- name: api
  containerPort: {{ .Values.core.archive.port }}
  protocol: TCP
{{- end -}}

{{- /* v2b.archive.address: the archive's address, its Service in v2b-archive at its port. */ -}}
{{- define "v2b.archive.address" -}}
http://archive.v2b-archive.svc:{{ .Values.core.archive.port }}
{{- end -}}

{{- /* v2b.archive.tokenDir: where v2b.archive.token mounts the archive's token. */ -}}
{{- define "v2b.archive.tokenDir" -}}
/var/run/secrets/v2b-archive
{{- end -}}

{{- /* v2b.archive.env: the two variables a caller of the archive is given, as items of a container's env. */ -}}
{{- define "v2b.archive.env" -}}
- name: V2B_ARCHIVE_URL
  value: {{ include "v2b.archive.address" . | quote }}
- name: V2B_ARCHIVE_TOKEN
  value: {{ printf "%s/token" (include "v2b.archive.tokenDir" .) | quote }}
{{- end -}}

{{- /*
v2b.archive.token: the pod's token for the audience v2b-archive, projected; (list . "volume") is the
item of the pod's volumes, (list . "mount") the item of a container's volumeMounts.
*/ -}}
{{- define "v2b.archive.token" -}}
{{- $root := index . 0 -}}
{{- $part := index . 1 -}}
{{- if eq $part "volume" -}}
- name: archive-token
  projected:
    sources:
    - serviceAccountToken:
        audience: v2b-archive
        expirationSeconds: 3600
        path: token
{{- else if eq $part "mount" -}}
- name: archive-token
  mountPath: {{ include "v2b.archive.tokenDir" $root }}
  readOnly: true
{{- else -}}
{{- fail (printf "v2b.archive.token: the part is volume or mount, not %q" $part) -}}
{{- end -}}
{{- end -}}

{{- /*
v2b.cluster.token: the pod's token for the cluster API's audience with the cluster's certificate
authority and the namespace beside it, at the path controller-runtime's in-cluster configuration reads;
(list . "volume") or (list . "mount").
*/ -}}
{{- define "v2b.cluster.token" -}}
{{- $part := index . 1 -}}
{{- if eq $part "volume" -}}
- name: cluster-token
  projected:
    sources:
    - serviceAccountToken:
        expirationSeconds: 3600
        path: token
    - configMap:
        name: kube-root-ca.crt
        items:
        - key: ca.crt
          path: ca.crt
    - downwardAPI:
        items:
        - path: namespace
          fieldRef:
            apiVersion: v1
            fieldPath: metadata.namespace
{{- else if eq $part "mount" -}}
- name: cluster-token
  mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  readOnly: true
{{- else -}}
{{- fail (printf "v2b.cluster.token: the part is volume or mount, not %q" $part) -}}
{{- end -}}
{{- end -}}

{{- /* v2b.workspace.claim: the name of the agent's volume claim, the agent's to make. */ -}}
{{- define "v2b.workspace.claim" -}}
{{ .Values.core.agentVolume }}
{{- end -}}

{{- /* v2b.workspace.volume: the agent's volume, as one item of a pod's volumes. */ -}}
{{- define "v2b.workspace.volume" -}}
- name: agent-home
  persistentVolumeClaim:
    claimName: {{ include "v2b.workspace.claim" . }}
{{- end -}}

{{- /*
v2b.securityContext: the restricted standard's settings as the user core.userID; (list . "pod") is a
pod's securityContext, (list . "container") a container's.
*/ -}}
{{- define "v2b.securityContext" -}}
{{- $root := index . 0 -}}
{{- $part := index . 1 -}}
{{- if eq $part "pod" -}}
runAsNonRoot: true
runAsUser: {{ $root.Values.core.userID }}
runAsGroup: {{ $root.Values.core.userID }}
fsGroup: {{ $root.Values.core.userID }}
seccompProfile:
  type: RuntimeDefault
{{- else if eq $part "container" -}}
allowPrivilegeEscalation: false
runAsNonRoot: true
capabilities:
  drop: [ALL]
seccompProfile:
  type: RuntimeDefault
{{- else -}}
{{- fail (printf "v2b.securityContext: the part is pod or container, not %q" $part) -}}
{{- end -}}
{{- end -}}

{{- /* v2b.timezone: the server's time zone, as text. */ -}}
{{- define "v2b.timezone" -}}
{{ required "timezone: the server's time zone is not set" .Values.timezone }}
{{- end -}}

{{- /* v2b.agentSettings.name: the name of the agent's settings object. */ -}}
{{- define "v2b.agentSettings.name" -}}
{{ .Values.core.agentSettings }}
{{- end -}}

{{- /* v2b.claude.name: the name of Claude's Deployment. */ -}}
{{- define "v2b.claude.name" -}}
{{ .Values.core.claudeDeployment }}
{{- end -}}

{{- /*
v2b.labels: a pod's labels, (dict "root" . "component" <one of core.components> "calls" (list ...)),
each call one of archive, cluster and internet, given as v2b/calls-<call>: "true".
*/ -}}
{{- define "v2b.labels" -}}
{{- $root := .root -}}
{{- if not (has .component $root.Values.core.components) -}}
{{- fail (printf "v2b.labels: %q is not one of core.components" .component) -}}
{{- end -}}
app.kubernetes.io/component: {{ .component }}
{{- range (.calls | default list) }}
{{- if not (has . (list "archive" "cluster" "internet")) }}
{{- fail (printf "v2b.labels: %q is not a call; archive, cluster or internet" .) }}
{{- end }}
v2b/calls-{{ . }}: "true"
{{- end }}
{{- end -}}

{{- /*
v2b.nodeAddress: the node's address, the InternalIP of the cluster's one Node read by lookup, else
core.nodeAddress; with neither, or with more than one Node, the render fails, so no open rule is ever
rendered.
*/ -}}
{{- define "v2b.nodeAddress" -}}
{{- $nodes := (lookup "v1" "Node" "" "").items | default list -}}
{{- if gt (len $nodes) 1 -}}
{{- fail (printf "the cluster has %d nodes; the chart is for one" (len $nodes)) -}}
{{- end -}}
{{- $address := "" -}}
{{- range $nodes -}}
{{- range .status.addresses -}}
{{- if eq .type "InternalIP" -}}{{- $address = .address -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- if not $address -}}{{- $address = .Values.core.nodeAddress -}}{{- end -}}
{{- if not $address -}}
{{- fail "the node's address: no Node answered lookup and core.nodeAddress is not set" -}}
{{- end -}}
{{- $address -}}
{{- end -}}
