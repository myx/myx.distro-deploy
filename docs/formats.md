# Formats

[Back to the README](../README.md)

These directives go in a project's `Declares` entry. The [project.inf manual](https://github.com/myx/myx.distro-.local/blob/main/sh-lib/help/Man.Project.Inf.file.help.md) describes the file format.

## image-install directives

Put these in a project's `Declares` to shape what happens on the target host.

- `image-install:context-variable:<name>:<operation>[:<value>...]` — set a variable
  on the host.
	- `create` — create the variable or array, only if it is not defined.
	- `change` — set the value, only if the variable is already defined.
	- `ensure` — create it, or make sure the array already contains the value.
	- `append` / `insert` — create it, or append the value whether or not it is present.
	- `update` — make sure a defined array contains the value.
	- `remove` — remove the value from the array; undefine it when no value is given.
	- `re-set` / `define` / `upsert` — set the variable, defined or not.
	- `delete` — undefine it; only when the current value matches, if one is given.
	- Examples:
		- `image-install:context-variable:HOST_TYPE:re-set:standalone`
		- `image-install:context-variable:LANGUAGES:insert:en`
		- `image-install:context-variable:LANGUAGES:remove:lv`
- `image-install:context-variable:<name>:{import|source}:{.|<projectName>}:<scriptPath>` —
  take the value from a file inside a project.
	- `image-install:context-variable:HOST_KEY:import:.:ssh/rsa.pub`
- `image-install:deploy-sync-files:<deploySourcePath>:<targetHostPath>` — copy prepared
  files onto the host.
	- `image-install:deploy-sync-files:data/settings:/usr/local/app/settings`
- `image-install:clone-deploy-file:<deploySourcePath>:<sourceFileName>:<targetNamePattern>[:<variableName>:<value>...]` —
  clone one prepared file into many.
	- `image-install:clone-deploy-file:data/settings:web/default:page-200.html:page-???.html:???:201:204`
	- `image-install:clone-deploy-file:data/settings:web/default:page-404.html:page-418.html`
- `image-install:exec-update-before:host/install/<scriptName>` — run a script before the install.
	- `image-install:exec-update-before:host/install/common-java.sh.txt`
- `image-install:exec-update-after:host/install/<scriptName>` — run a script after the install.
	- `image-install:exec-update-after:host/install/service-restart.txt`
- Patch content at each step. `<scriptSourceName>` of `.` means this project's own source.
	- `image-install:deploy-patch-script-prefix:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]`
	- `image-install:source-patch-script:<deploySourcePath>:<scriptSourceName>:host/scripts/<scriptName>`
	- `image-install:deploy-patch-script:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]`
	- `image-install:deploy-patch-script-suffix:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]`
	- `image-install:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetHostPath>`
	- `image-install:deploy-applied-script:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]`
	- Examples:
		- `image-install:source-patch-script:data/settings:.:host/scripts/patch-on-deploy.txt`
		- `image-install:target-patch-script:.:host/scripts/patch-on-deploy.txt:/usr/local/app/settings`

## Build stages

Deploy owns the last two of the six pipeline stages.

- `image-process` — builders `4???-*`. Builds single-file distro and repository
  indices, per-target concatenated deploy scripts, and per-target merged settings.
- `image-install` — builders `5???-*`. Runs the deploy tasks on the targets.

`myx.distro-source` documents the first four.

## Workspace folders

- `/source` — source code and projects. Editable and committable.
- `/export` — export resources, generated or cloned.
- `/distro` — the whole prepared project tree, generated or cloned.
	- `/distro/repo[/group]/project` — project folder structure.
- `/actions` — generated workspace actions. Executable, not editable.
- `/.local` — installed tools and system integrations.
	- `/.local/system-index` — generated system index.
	- `/.local/source-cache` — build cache, written before source-prepare.
	- `/.local/output-cache` — output products. May be absent in pure deploy mode.
