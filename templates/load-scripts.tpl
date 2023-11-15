{{- /*

  Loads all script files into the "/scripts" mount point.

*/ -}}

{{- define "load_scripts" -}}
  {{- $global := index . 0 -}}
- name: load-scripts
  image: {{ $global.Values.images.minimal }}
  workingDir: /scripts
  script: |
    set -e
  {{- range $i, $prefix := . -}}
    {{- if gt $i 0 }}
      {{- range $path, $content := $global.Files.Glob "scripts/*.sh" }}
        {{- $name := trimPrefix "scripts/" $path }}
        {{- if or ( hasPrefix $prefix $name ) ( hasPrefix "common" $name ) }}
    printf '%s' "{{ $content | toString | b64enc }}" |base64 -d >{{ $name }}
        {{- end }}
      {{- end }}
    chmod +x {{ $prefix }}*.sh
    {{- end }}
  {{- end }}
  volumeMounts:
    - name: scripts-dir
      mountPath: /scripts
{{- end -}}
