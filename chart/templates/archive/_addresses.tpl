{{- /*
archive.platformAddresses: the file platform-addresses.env, key=value a line, from the value
archive.platformAddresses; the ConfigMap holds it and the pod's annotation is its sha256sum.
*/ -}}
{{- define "archive.platformAddresses" -}}
{{- range $platform, $address := .Values.archive.platformAddresses }}
{{ $platform }}={{ $address }}
{{- end }}
{{- end -}}
