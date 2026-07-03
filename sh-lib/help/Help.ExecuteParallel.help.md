📘 syntax: ExecuteParallel.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]
📘 syntax: ExecuteParallel.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]
📘 syntax: ExecuteParallel.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]
📘 syntax: ExecuteParallel.fn.sh <project-selector> --display-targets [<ssh arguments>...]
📘 syntax: ExecuteParallel.fn.sh [--help]

##  Summary:

		Runs commands against selected SSH targets in parallel background jobs.

##  Arguments:

		project-selector
			Required positional argument at position 1 unless using --select-from-env.

##  Options:

		--all-targets
			Uses all deploy targets.

		--select-from-env
			Uses MDSC_SELECT_PROJECTS.

		--no-sleep
			Disables startup delay before execution.

		--non-interactive
			Suppresses task explanation and sleep delay.

		--ssh-name <name>
		--ssh-host <host>
		--ssh-port <port>
		--ssh-user <user>
		--ssh-home <path>
		--ssh-args <args>
			SSH overrides for target command composition. Last value wins.

		--execute-post-process <command>
			Post-processes combined output stream.

		--display-targets
			Prints resolved targets.

		--execute-stdin
			Executes stdin body on each target.

		--execute-script <script-name>
			Executes script file content on each target.

		--execute-command <command>
			Executes command string on each target.

		--help
			Prints command help and exits.

##  Examples:

		# Reference syntax for parallel stdin execution.
		`ExecuteParallel.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]`

		# Reference syntax for parallel script-file execution.
		`ExecuteParallel.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]`

		# Show full help and option reference.
		`ExecuteParallel.fn.sh --help`

		# List all resolved targets before execution.
		`ExecuteParallel.fn.sh --select-all --display-targets -l root`

		# Execute stdin payload in parallel on selector-matched projects.
		`ExecuteParallel.fn.sh --select-projects l6 --execute-stdin -l root`

		# Execute stdin payload in parallel on merged-keyword target set.
		`ExecuteParallel.fn.sh --select-merged-keywords l6 --execute-stdin -l root`

		# Run one inline command in parallel using login override.
		`ExecuteParallel.fn.sh --select-projects l6 -l root uname -a`

		# Run one inline command in parallel with explicit SSH user option.
		`ExecuteParallel.fn.sh --select-projects l6 --ssh-user root uname -a`

		# Run command-mode execution in parallel for selected projects.
		`ExecuteParallel.fn.sh --select-projects l6 --execute-command`

		# Run maintenance command in parallel on all selected targets.
		`ExecuteParallel.fn.sh --select-all -l root myx.common install/myx.common-reinstall`

		# Use explicit execute-command mode across all selected targets.
		`ExecuteParallel.fn.sh --select-all --execute-command`

		# Run parallel execution on provides-selected targets.
		`ExecuteParallel.fn.sh --select-provides`

		# Run a setup script file in parallel for a project selector.
		`ExecuteParallel.fn.sh --select-projects ndns- --execute-script source/ndm/cloud.all/setup.common-ndns/host/install/common-ndns-setup.txt -l root bash`

