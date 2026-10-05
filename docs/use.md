# Use

[Back to the README](../README.md)

## Getting started

Open the console first. [Installation](installation.md) shows how.

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
`--remove-` forms — is the one `myx.distro-system` documents, and every command
prints it under `--help`.
