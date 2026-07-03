📘 syntax: DeployProjectSsh.fn.sh <project> --do-exec|--do-sync|--do-both|--do-none
📘 syntax: DeployProjectSsh.fn.sh [--help]

##  Summary:

		Legacy/unfinished deploy script variant that builds sync/exec payloads for one
		project and can print intermediate artifacts.

##  Arguments:

		project
			Required positional argument at position 1. Project selector/name.

##  Options:

		--project
			Marker option for explicit project mode in caller flow.

		--explicit-noop
			No-op parser marker; ignored.

		--select-from-env
			Uses project selection from MDSC_SELECT_PROJECTS.

		--do-exec
		--no-exec
		--do-sync
		--no-sync
		--do-none
		--do-full
		--do-both
			Execution/sync mode flags. If conflicting flags are provided, last one wins.

		--print-folders
		--print-files
		--print-sync-tasks
		--print-installer
		--print-ssh-target
			Print-only modes for generated data.

		--deploy-rsync-direct
		--deploy-script-rsync
			Reserved/incomplete paths in this unfinished script branch.

		--help
			Prints command help and exits.

##  Notes:

		This script is unfinished and has entry-point mismatch in its case block.
		Use DeployProjectSsh.fn.sh for active deploy flow.

##  Examples:

				# Deploy one project and choose execution mode (exec, sync, both, or dry run)
		`DeployProjectSsh.fn.sh <project> --do-exec|--do-sync|--do-both|--do-none`

				# Re-run with a different mode value when validating workflow behavior
		`DeployProjectSsh.fn.sh <project> --do-exec|--do-sync|--do-both|--do-none`

				# Print command help and exit
		`DeployProjectSsh.fn.sh --help`
