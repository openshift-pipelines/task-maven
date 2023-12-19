# `maven` Tekton Task

The `maven` Task can be used to run a Maven goal on a simple or multi-module maven project.

## Workspaces

### `source`

The `source` is a required workspace, that contains the source of the "maven" project to build. It should contain a `pom.xml`.

## Parameters

| Parameter          | Type     | Default    | Description                                                                        |
|:-------------------|:---------|:-----------|:-----------------------------------------------------------------------------------|
| `GOALS`            | `string` | `package`  | The `maven` goal(s) to run                                                         |
| `MAVEN_MIRROR_URL` | `string` | "" (empty) | The maven repository mirror URL to use                                             |
| `SUBDIRECTORY`     | `string` | `.`        | The subdirectory of the `source` workspace on which we want to execute maven goals |

