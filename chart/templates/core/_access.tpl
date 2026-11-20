{{- /*
core.bind: the binding of one ServiceAccount to one role, (dict "name" <the binding's name> "namespace"
<where it binds, "" for the whole cluster> "role" <Role or ClusterRole> "roleName" <its name>
"account" (list <namespace> <name>)). A namespace given makes a RoleBinding there; none, a
ClusterRoleBinding.
*/ -}}
{{- define "core.bind" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: {{ if .namespace }}RoleBinding{{ else }}ClusterRoleBinding{{ end }}
metadata:
  name: {{ .name }}
  {{- with .namespace }}
  namespace: {{ . }}
  {{- end }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: {{ .role }}
  name: {{ .roleName }}
subjects:
- kind: ServiceAccount
  namespace: {{ index .account 0 }}
  name: {{ index .account 1 }}
{{- end -}}
