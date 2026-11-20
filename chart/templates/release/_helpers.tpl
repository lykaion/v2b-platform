{{- /*
v2b.release.atOrAbove: a shell function, at_or_above <text> <step>, true when the first version
X.Y.Z[+k3sN] in <text> is at or above <step>'s, its k3s build compared after the patch, so a step
that raises only the build still upgrades; a version with no build reads as build 0.
*/ -}}
{{- define "v2b.release.atOrAbove" -}}
at_or_above() {
  have=$(echo "$1" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(\+k3s[0-9]+)?' | head -n 1 | sed 's/+k3s/./')
  want=$(echo "$2" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(\+k3s[0-9]+)?' | head -n 1 | sed 's/+k3s/./')
  [ -n "$have" ] && [ -n "$want" ] || return 1
  [ "$(printf '%s\n%s\n' "$want" "$have" | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | head -n 1)" = "$want" ]
}
{{- end -}}

{{- /*
v2b.release.controlPlane: the node selector of the plans, the control-plane node.
*/ -}}
{{- define "v2b.release.controlPlane" -}}
matchExpressions:
- key: node-role.kubernetes.io/control-plane
  operator: In
  values: ["true"]
{{- end -}}
