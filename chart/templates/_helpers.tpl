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

{{- /* v2b.workspace.volume: the agent's volume, as one item of a pod's volumes, named as its claim. */ -}}
{{- define "v2b.workspace.volume" -}}
- name: {{ include "v2b.workspace.claim" . }}
  persistentVolumeClaim:
    claimName: {{ include "v2b.workspace.claim" . }}
{{- end -}}

{{- /* v2b.workspace.root: the mount root, where every pod mounts the agent's volume, as text. */ -}}
{{- define "v2b.workspace.root" -}}
{{ .Values.core.workspace.mountRoot }}
{{- end -}}

{{- /*
v2b.workspace.mounts: a role's mounts of the agent's volume, (list . "<role>"), as items of a
container's volumeMounts: each directory of core.workspace.dirs its cell names, at the mount root, read-only
where the cell reads. A role with no cell fails the render.
*/ -}}
{{- define "v2b.workspace.mounts" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- $n := 0 -}}
{{- range $root.Values.core.workspace.dirs -}}
{{- $cell := index .cells $role | default "" -}}
{{- if $cell -}}
{{- if not (has $cell (list "writes" "reads" "uses")) -}}
{{- fail (printf "v2b.workspace.mounts: %s's cell for %s is %q; writes, reads or uses" .path $role $cell) -}}
{{- end -}}
{{- $n = add1 $n }}
- name: {{ include "v2b.workspace.claim" $root }}
  mountPath: {{ printf "%s/%s" (include "v2b.workspace.root" $root) .path }}
  subPath: {{ .path }}
  readOnly: {{ eq $cell "reads" }}
{{- end -}}
{{- end -}}
{{- if eq $n 0 -}}
{{- fail (printf "v2b.workspace.mounts: %q has no cell in core.workspace.dirs" $role) -}}
{{- end -}}
{{- end -}}

{{- /*
v2b.workspace.whole: Claude's one mount of the agent's volume, whole, at the mount root, writable, as
an item of a container's volumeMounts; charttest refuses it in any other pod.
*/ -}}
{{- define "v2b.workspace.whole" -}}
- name: {{ include "v2b.workspace.claim" . }}
  mountPath: {{ include "v2b.workspace.root" . }}
{{- end -}}

{{- /*
v2b.workspace.signIn: the variable naming the sign-in's directory to claude, as an item of a
container's env, in every container that mounts it; its name is claude.SignInDirEnv.
*/ -}}
{{- define "v2b.workspace.signIn" -}}
- name: CLAUDE_SECURESTORAGE_CONFIG_DIR
  value: {{ printf "%s/%s" (include "v2b.workspace.root" .) .Values.core.workspace.signIn | quote }}
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
v2b.nodeAddress: the node's IPv4 address, chosen by v2b.nodeAddress.choose from the cluster's Nodes as
lookup reads them.
*/ -}}
{{- define "v2b.nodeAddress" -}}
{{- include "v2b.nodeAddress.choose" (list . ((lookup "v1" "Node" "" "").items | default list)) -}}
{{- end -}}

{{- /*
v2b.nodeAddress.choose: (list . <nodes>), the node's address the rules name: the IPv4 InternalIP of the
one Node, whatever the order of its addresses, else core.nodeAddress. The pod network is IPv4 alone, so an
IPv6 address is never chosen, and core.nodeAddress given as one fails the render. With no address, or with
more than one Node, the render fails, so no open rule is ever rendered. A Node answering lookup comes in
here, so a render with no cluster feeds it a list of Nodes of its own.
*/ -}}
{{- define "v2b.nodeAddress.choose" -}}
{{- $root := index . 0 -}}
{{- $nodes := index . 1 -}}
{{- $ipv4 := `^((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])$` -}}
{{- if gt (len $nodes) 1 -}}
{{- fail (printf "the cluster has %d nodes; the chart is for one" (len $nodes)) -}}
{{- end -}}
{{- $address := "" -}}
{{- range $nodes -}}
{{- range .status.addresses -}}
{{- if and (eq .type "InternalIP") (not $address) (regexMatch $ipv4 .address) -}}{{- $address = .address -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- if not $address -}}
{{- $given := $root.Values.core.nodeAddress | default "" | toString -}}
{{- if and $given (contains ":" $given) -}}
{{- fail (printf "the node's address: core.nodeAddress %q is an IPv6 address; the rules need the node's IPv4 address" $given) -}}
{{- end -}}
{{- if and $given (not (regexMatch $ipv4 $given)) -}}
{{- fail (printf "the node's address: core.nodeAddress %q is not an IPv4 address" $given) -}}
{{- end -}}
{{- $address = $given -}}
{{- end -}}
{{- if not $address -}}
{{- fail "the node's address: no Node answered lookup with an IPv4 InternalIP and core.nodeAddress is not set" -}}
{{- end -}}
{{- $address -}}
{{- end -}}
