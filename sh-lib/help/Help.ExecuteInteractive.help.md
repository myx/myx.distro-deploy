📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]
📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]
📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]
📘 syntax: ExecuteInteractive.fn.sh <project-selector> --display-targets [<ssh arguments>...]
📘 syntax: ExecuteInteractive.fn.sh [--help]

##  Summary:

		Runs a command/script interactively against selected deploy SSH targets.

##  Arguments:

		project-selector
			Required positional argument at position 1 unless selection is taken from
			--select-from-env path.

##  Options:

		--project <project>
			Internal/project selection path for explicit project mode.

		--all-targets
			Targets all deploy SSH targets.

		--select-from-env
			Uses MDSC_SELECT_PROJECTS as project selection input.

		--execute-stdin
			Reads command/script body from stdin and executes on target(s).

		--execute-script <script-name>
			Executes script file content.

		--execute-command <command>
			Executes provided command string.

		--display-targets
			Prints resolved targets instead of executing commands.

		--help
			Prints command help and exits.

##  Notes:

		Execution mode parsing is delegated through selector/target helpers. This command
		keeps an interactive flow and inserts pre-run delay.

##  Examples:

		# Reference syntax for interactive stdin execution on selected targets.
		`ExecuteInteractive.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]`

		# Reference syntax for interactive script-file execution on selected targets.
		`ExecuteInteractive.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]`

		# Show full help and option reference.
		`ExecuteInteractive.fn.sh --help`

		# Run command interactively on projects matched by selector.
		`ExecuteInteractive.fn.sh --select-projects l6 -l root uname -a`

		# Run command interactively on targets selected by merged keyword filter.
		`ExecuteInteractive.fn.sh --select-merged-keywords l6 -l root uname -a`

		# Run command interactively on targets selected by provides filter.
		`ExecuteInteractive.fn.sh --select-provides deploy-ssh-target: -l root uname -a`

		# Run command interactively across all selected deploy targets.
		`ExecuteInteractive.fn.sh --select-all -l root uname -a`

