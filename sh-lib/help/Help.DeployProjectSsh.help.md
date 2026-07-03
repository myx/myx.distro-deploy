📘 syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|home|args} <value>] [--match <install-script-filter>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}
📘 syntax: DeployProjectSsh.fn.sh --project <project> [--match <install-script-filter>] --print-{files|sync-tasks|installer|ssh-targets|deploy-patch-scripts|context-variables|sync-script|exec-script|full-script}
📘 syntax: DeployProjectSsh.fn.sh --project <project> [--use-gz|--use-bz2|--use-xz] ...
📘 syntax: DeployProjectSsh.fn.sh [--help]

##  Summary:

		Builds deploy sync/exec scripts for one project, prints them, saves them, or runs
		them remotely on resolved SSH targets.

##  Arguments:

		None. This command accepts no positional arguments; project is provided by --project.

##  Options:

		--project <project>
			Required for direct mode. Selects one project into MDSC_PRJ_NAME.

		--ssh-name <name>
		--ssh-host <host>
		--ssh-port <port>
		--ssh-user <user>
		--ssh-home <path>
		--ssh-args <args>
			Optional SSH overrides. For duplicate keys, last value wins.

		--prepare-exec
		--prepare-sync
		--prepare-full
		--prepare-none
			Controls prepare step before deploy. If multiple are provided, last flag wins.

		--match <install-script-filter>
			Filters install patch scripts used in generated installer.

		--use-gzip
		--use-gz
		--use-bzip2
		--use-bz2
		--use-xz
			Compression mode selector for transfer payload. Last selector wins.

		--no-sleep
			Skips pre-execution sleep delay.

		--print-files
		--print-sync-tasks
		--print-deploy-patch-scripts
		--print-context-variables
		--print-installer
		--print-ssh-targets
			Print-only inspection modes.

		--print-sync-script
		--print-exec-script
		--print-full-script
			Prints generated remote deploy script variant.

		--save-sync-script
		--save-exec-script
		--save-full-script
			Saves generated script to deploy output cache and prints resulting path.

		--deploy-sync
		--deploy-exec
		--deploy-full
			Executes generated script remotely for resolved targets.

		--deploy-none
			No execution mode; returns success after parsing.

		--help
			Prints command help and exits.

##  Notes:

		If first token is a selector option (not --project), command delegates selection
		to ListDistroProjects with --select-execute-default DeployProjectsSsh.

##  Examples:

		# Reference syntax for project-scoped deploy with optional SSH overrides and prepare/deploy mode.
		`DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|home|args} <value>] [--match <install-script-filter>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}`

		# Reference syntax for print-only inspection modes.
		`DeployProjectSsh.fn.sh --project <project> [--match <install-script-filter>] --print-{files|sync-tasks|installer|ssh-targets|deploy-patch-scripts|context-variables|sync-script|exec-script|full-script}`

		# Show full help and option reference.
		`DeployProjectSsh.fn.sh --help`

		# Reference syntax for project-scoped deploy with optional SSH overrides and prepare/deploy mode.
		`DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--match <install-script-filter>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}`

		# Compact print-mode syntax variant.
		`DeployProjectSsh.fn.sh --project <project> [--match <install-script-filter>] --print-{files|sync-tasks|installer|ssh-targets|deploy-patch-scripts|context-variables|full-script}`

		# Select compression mode for transfer payload generation.
		`DeployProjectSsh.fn.sh --project <project> [--use-bz2|--use-xz] ...`

		# Sync deployment for one explicitly selected project.
		`DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --prepare-sync --deploy-sync`

		# Selector-based exec deployment with explicit SSH user/home overrides.
		`DeployProjectSsh.fn.sh --select-projects ndss001 --no-sleep --ssh-user root --ssh-home ~/.ssh --prepare-full --deploy-exec`

		# Run sync deployment for exactly one selected project.
		`DeployProjectSsh.fn.sh --select-one-project ndns001 --prepare-sync --deploy-sync`

		# Resolve and prepare in sync mode, but do not execute remote deploy.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-sync --deploy-none`

		# Skip prepare phase and run sync deployment only.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-none --deploy-sync`

		# Skip prepare phase and run exec deployment only.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-none --deploy-exec`

		# Prepare exec artifacts and then run exec deployment.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-exec --deploy-exec`

		# Run complete prepare+deploy flow for one project.
		`DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --prepare-full --deploy-full`

		# Generate and print full deploy script without running it.
		`DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --prepare-full --print-full-script`

		# Print deploy patch script list for selected project.
		`DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --print-deploy-patch-scripts`

		# Print effective context variables used for deploy script generation.
		`DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --print-context-variables`

		# Preview resolved SSH targets without deployment.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --prepare-none --print-ssh-targets`

		# Preview SSH targets with explicit host override.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --ssh-host 192.168.1.17 --prepare-none --print-ssh-targets`

		# Preview SSH targets with explicit port override.
		`DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --ssh-port 22 --prepare-none --print-ssh-targets`

		# Preview SSH targets with explicit SSH user override.
		`DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --ssh-user guest --prepare-none --print-ssh-targets`

