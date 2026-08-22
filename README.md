# myx.distro-deploy

Installs a built distro image onto hosts. It resolves which SSH targets a project
set maps to, prepares per-target files, settings and scripts, and runs them over
SSH — one host, a sequence of hosts, or a whole fleet in parallel.

## Getting started

Install the deploy toolset into a workspace, then open the deploy console:

	bash .local/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh --install-distro-deploy
	./DistroDeployConsole.sh

Inside the console, call a tool by its full name (`.fn.sh` included), or through
the `Deploy` or `Distro` dispatcher:

	ListSshTargets.fn.sh --all-targets
	Deploy ListSshTargets --all-targets

Run one command without an interactive session:

	echo "Deploy ListSshTargets --all-targets" | ./DistroDeployConsole.sh --non-interactive

## Common tasks

Always start by checking what a selector resolves to. This connects to nothing:

	ListSshTargets.fn.sh --all-targets
	ListSshTargets.fn.sh --select-projects <project-name-part>

Open a shell on exactly one target. It refuses a selector matching more than one,
without connecting:

	ShellTo.fn.sh <project-name-part>

Open a `screen` session on one target, falling back to a plain shell:

	ScreenTo.fn.sh <project-name-part>

Run one command across many targets, one after another:

	ExecuteSequence.fn.sh --select-projects <mask> --execute-command 'uname -a'

Run it across many targets at once:

	ExecuteParallel.fn.sh --select-projects <mask> --ssh-user root --no-sleep --execute-command 'uname -a'

Preview a project's deploy without touching a host:

	DeployProjectSsh.fn.sh --project <project> --print-ssh-targets
	DeployProjectSsh.fn.sh --project <project> --print-full-script

Deploy one project to its resolved targets:

	DeployProjectSsh.fn.sh --project <project> --deploy-full

Regenerate deploy-side workspace files:

	RebuildActionsFromDistro.fn.sh
	RebuildKnownHostsFromDistro.fn.sh

Put every `--ssh-*`, `--no-sleep`, `--non-interactive` and `--execute-post-process`
option **before** `--execute-command` / `--execute-script` / `--execute-stdin` /
`--display-targets` — the option parser stops at the first token it does not
recognise, and anything after that leaks onto the remote command line.

## Selecting targets

`--select-projects <mask>` matches a substring of the project path, which is the
simplest way to reach a fixed fleet:

	Deploy ExecuteParallel --select-projects setup.host- --ssh-user root --no-sleep --execute-command 'uptime'

The full selector vocabulary — `--select-all`, `--select-changed`,
`--select-provides`, `--select-keywords`, and the matching `--filter-` and
`--remove-` forms — is the same one `myx.distro-system` documents, and every
command prints it under `--help`.

## Commands

Pick the narrowest tool that fits the job:

- `ListSshTargets.fn.sh` — report what a selector resolves to; acts on nothing.
- `ShellTo.fn.sh` — open a shell on exactly one target.
- `ScreenTo.fn.sh` — open a remote `screen` session on one target.
- `LocalTo.fn.sh` — enter a project-local session for one resolved target.
- `ExecuteSequence.fn.sh` — run a command or script across many targets, one at a time.
- `ExecuteParallel.fn.sh` — run it across many targets in parallel.
- `ExecuteInteractive.fn.sh` — run it interactively against selected targets.
- `DeployProjectSsh.fn.sh` — build, print, save or run one project's deploy scripts.
- `InstallPrepareFiles.fn.sh` — build a project's file-preparation plan; print, save or materialise it.
- `InstallPrepareScript.fn.sh` — build a project's install patch-script bundle.
- `Reinstall.fn.sh` — reconnect to one target and run its reinstall flow.
- `RebuildActionsFromDistro.fn.sh` — regenerate workspace actions for the active deploy environment.
- `RebuildKnownHostsFromDistro.fn.sh` — regenerate workspace `ssh/known_hosts`.
- `DistroDeployTools.fn.sh` — re-create the deploy console launcher, set workspace options, upgrade deploy tools.

## image-install directives

Put these in a project's `Declares` to shape what happens on the target host.

Set a context variable on the host:

	image-install:context-variable:<name>:<operation>[:<value>...]
	image-install:context-variable:<name>:{import|source}:{.|<projectName>}:<scriptPath>

	image-install:context-variable:HOST_TYPE:re-set:standalone
	image-install:context-variable:LANGUAGES:insert:en
	image-install:context-variable:LANGUAGES:remove:lv

Operations:

	create        create the variable or array only if it is not defined
	change        set the value only if the variable is already defined
	ensure        create it, or make sure the array already contains the value
	append|insert create it, or append the value whether or not it is present
	update        make sure a defined array contains the value
	remove        remove the value from the array; undefine it if no value given
	re-set|define|upsert  set the variable, defined or not
	import|source define it from a file inside the project
	delete        undefine it; only when the current value matches, if one is given

Copy prepared files onto the host:

	image-install:deploy-sync-files:<deploySourcePath>:<targetHostPath>

	image-install:deploy-sync-files:data/settings:/usr/local/app/settings

Clone one prepared file into many:

	image-install:clone-deploy-file:<deploySourcePath>:<sourceFileName>:<targetNamePattern>[:<variableName>:<value>...]

	image-install:clone-deploy-file:data/settings:web/default:page-200.html:page-???.html:???:201:204
	image-install:clone-deploy-file:data/settings:web/default:page-404.html:page-418.html

Run scripts around the install:

	image-install:exec-update-before:host/install/<scriptName>
	image-install:exec-update-after:host/install/<scriptName>

	image-install:exec-update-before:host/install/common-java.sh.txt
	image-install:exec-update-after:host/install/service-restart.txt

Patch content at each step:

	image-install:deploy-patch-script-prefix:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]
	image-install:source-patch-script:<deploySourcePath>:<scriptSourceName>:host/scripts/<scriptName>
	image-install:deploy-patch-script:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]
	image-install:deploy-patch-script-suffix:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]
	image-install:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetHostPath>
	image-install:deploy-applied-script:<scriptSourceName>:host/scripts/<scriptName>[:<relativePath>]

	image-install:source-patch-script:data/settings:.:host/scripts/patch-on-deploy.txt
	image-install:target-patch-script:.:host/scripts/patch-on-deploy.txt:/usr/local/app/settings

`<scriptSourceName>` of `.` means this project's own source.

## Build stages

Deploy owns the last two of the five pipeline stages:

| Stage | Builders | Does |
| --- | --- | --- |
| `image-process` | `4???-*` | build single-file indices, per-target deploy scripts and merged settings |
| `image-install` | `5???-*` | run the deploy tasks on the targets |

`myx.distro-source` documents the first three.

## Workspace folders

	/source                 source code and projects — editable, committable
	/export                 export resources, generated or cloned
	/distro                 whole prepared project tree, generated or cloned
	/actions                generated workspace actions, executable, not editable
	/.local                 installed tools and system integrations
	/.local/distro-index    generated system index
	/.local/source-cache    build cache, written before source-prepare
	/.local/output-cache    output products; may be absent in pure deploy mode

## Getting help

- `<Tool>.fn.sh --help` prints full syntax, options and examples for any command above.
- `Deploy --help` prints the deploy-context dispatcher syntax; `Deploy --info` prints the current context.
- Press TAB after a command name and a space for shell completion.

## Related packages

- [myx.distro](https://github.com/myx/myx.distro) — the distro system overview.
- [myx.distro-.local](https://github.com/myx/myx.distro-.local) — install and launch the toolsets.
- [myx.distro-system](https://github.com/myx/myx.distro-system) — shared indexing and query tools.
- [myx.distro-source](https://github.com/myx/myx.distro-source) — build source into a distro image.
- [myx.distro-remote](https://github.com/myx/myx.distro-remote) — drive a workspace on another machine.
