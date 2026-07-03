📘 syntax: ExecuteSequence.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]
📘 syntax: ExecuteSequence.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]
📘 syntax: ExecuteSequence.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]
📘 syntax: ExecuteSequence.fn.sh <project-selector> --display-targets [<ssh arguments>...]
📘 syntax: ExecuteSequence.fn.sh [--help]

##  Summary:

		Runs commands against selected SSH targets sequentially.

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

		# Reference syntax for sequential stdin execution.
		`ExecuteSequence.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]`

		# Reference syntax for sequential script-file execution.
		`ExecuteSequence.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]`

		# Show full help and option reference.
		`ExecuteSequence.fn.sh --help`

		# Execute stdin payload sequentially for selector-matched projects.
		`ExecuteSequence.fn.sh --select-projects l6 --execute-stdin -l root`

		# Execute stdin payload sequentially with explicit SSH user override.
		`ExecuteSequence.fn.sh --select-projects l6 --ssh-user root --execute-stdin`

		# Execute stdin payload sequentially for merged-keyword target set.
		`ExecuteSequence.fn.sh --select-merged-keywords l6 --execute-stdin -l root bash`

		# Run inline command sequentially across all selected targets.
		`ExecuteSequence.fn.sh --select-all uname -a`

		# Run inline command sequentially across all targets as root.
		`ExecuteSequence.fn.sh --select-all --ssh-user root uname -a`

		# Run sequential execution on provides-selected targets.
		`ExecuteSequence.fn.sh --select-provides`

		# Run setup script sequentially for selector-matched projects.
		`ExecuteSequence.fn.sh --select-projects ndns- --execute-script source/ndm/cloud.all/setup.common-ndns/host/install/common-ndns-setup.txt -l root bash`

