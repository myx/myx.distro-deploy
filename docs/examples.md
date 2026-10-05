# Examples

[Back to the README](../README.md)

## Look before you act

List the targets a selector resolves to. This connects to nothing:

	ListSshTargets.fn.sh --select-projects <project-name-part>

## Run one command across a fleet

Run a command on each target in turn:

	ExecuteSequence.fn.sh --select-projects setup.host- --ssh-user root --no-sleep --execute-command 'uname -a'

Run it on every target at once:

	ExecuteParallel.fn.sh --select-projects setup.host- --ssh-user root --no-sleep --execute-command 'uptime'

## Run a script on one target

Send a script file from the workspace `source` directory:

	ShellTo.fn.sh <project-name-part> --execute-script <path-under-source>

Or pipe the script on stdin:

	ShellTo.fn.sh <project-name-part> --execute-stdin

## Preview, then deploy one project

	DeployProjectSsh.fn.sh --project <project> --print-ssh-targets
	DeployProjectSsh.fn.sh --project <project> --print-installer
	DeployProjectSsh.fn.sh --project <project> --deploy-full

Prepare the artefacts without running them:

	DeployProjectSsh.fn.sh --select-projects <name-part> --prepare-sync --deploy-none
