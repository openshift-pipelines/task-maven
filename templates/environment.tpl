{{- /*

  This template is meant to translate the Tekton placeholder utilized by the shell scripts, thus the
  scripts can rely on a pre-defined and repetable way of consuming Tekton attributes.

    Example:
      The placeholder `workspaces.a.b` becomes `WORKSPACES_A_B`

*/ -}}

{{- define "environment" -}}
  {{- range $v := index . 0 }}
- name: {{ $v | upper | replace "." "_" | replace "-" "_" }}
  value: "$({{ $v }})"
  {{- end }}
{{- end -}}
