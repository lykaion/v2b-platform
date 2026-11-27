{{- /*
dreamers.pod: the pod every dreamer runs in, as a CronJob's pod template, (dict "root" . "component"
<summaries, ledger or digest> "command" (list ...) "archive" <bool>). Every shared name is reached
through the core's helpers. The pod sets no HOME and no working directory and mounts nothing at the
mount root itself: dreamers.Main sets both from workspace.MountRoot. Claude's own configuration is on
the pod's /tmp, and the agent's settings are mounted whole, read-only and optional, at /etc/claude-code.
*/ -}}
{{- define "dreamers.pod" -}}
{{- $root := .root -}}
{{- $calls := list "internet" -}}
{{- if .archive -}}{{- $calls = list "archive" "internet" -}}{{- end -}}
metadata:
  labels:
    {{- include "v2b.labels" (dict "root" $root "component" .component "calls" $calls) | nindent 4 }}
spec:
  serviceAccountName: dreamer
  automountServiceAccountToken: false
  enableServiceLinks: false
  restartPolicy: Never
  securityContext:
    {{- include "v2b.securityContext" (list $root "pod") | nindent 4 }}
  containers:
  - name: {{ .component }}
    image: {{ $root.Values.core.images.claude }}
    command: {{ toJson .command }}
    env:
    - name: V2B_CLAUDE
      value: claude
    - name: CLAUDE_CONFIG_DIR
      value: /tmp/claude
    - name: DISABLE_AUTOUPDATER
      value: "1"
    - name: TZ
      value: {{ include "v2b.timezone" $root | quote }}
    {{- include "v2b.workspace.signIn" $root | nindent 4 }}
    {{- if .archive }}
    {{- include "v2b.archive.env" $root | nindent 4 }}
    {{- end }}
    securityContext:
      {{- include "v2b.securityContext" (list $root "container") | nindent 6 }}
      readOnlyRootFilesystem: true
    resources:
      requests:
        cpu: 50m
        memory: 256Mi
      limits:
        memory: 1Gi
    volumeMounts:
      {{- include "v2b.workspace.mounts" (list $root .component) | nindent 6 }}
      {{- if .archive }}
      {{- include "v2b.archive.token" (list $root "mount") | nindent 6 }}
      {{- end }}
      - name: tmp
        mountPath: /tmp
      - name: settings
        mountPath: /etc/claude-code
        readOnly: true
  volumes:
    {{- include "v2b.workspace.volume" $root | nindent 4 }}
    {{- if .archive }}
    {{- include "v2b.archive.token" (list $root "volume") | nindent 4 }}
    {{- end }}
    - name: tmp
      emptyDir:
        sizeLimit: {{ $root.Values.dreamers.tmpSize }}
    - name: settings
      configMap:
        name: {{ include "v2b.agentSettings.name" $root }}
        optional: true
{{- end -}}
