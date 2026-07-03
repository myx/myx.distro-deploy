📘 syntax: ListSshTargets.fn.sh <project-selector> [--line-prefix <prefix>] [--line-suffix <suffix>] [<ssh arguments>...]
📘 syntax: ListSshTargets.fn.sh [--no-project-column] [--no-target-column] --all-targets [<ssh arguments>...]
📘 syntax: ListSshTargets.fn.sh [--line-prefix <prefix>] [--line-suffix <suffix>] --all-targets [<ssh arguments>...]
📘 syntax: ListSshTargets.fn.sh [--help]

##  Summary:

		Resolves and prints deploy SSH targets for selected project(s) or all targets.

##  Arguments:

		project-selector
			Optional positional selector when not using --all-targets. If omitted, selection
			can come from delegated selector flow or --select-from-env.

##  Options:

		--all-targets
			Lists all deploy targets.

		--select-from-env
			Uses MDSC_SELECT_PROJECTS as project selection input.

		--line-prefix <prefix>
			Prepends prefix to each output line.

		--line-suffix <suffix>
			Appends suffix to each output line.

		--no-project-column
			Omits project column in rendered output rows.

		--no-target-column
			Omits target column in rendered output rows.

		--ssh-host <host>
		--ssh-port <port>
		--ssh-user <user>
		--ssh-home <path>
		--ssh-args <args>
			Overrides SSH values in emitted target command line.

		--help
			Prints command help and exits.

##  Examples:

		# List SSH targets for projects matching selector with optional line formatting
		`ListSshTargets.fn.sh <project-selector> [--line-prefix <prefix>] [--line-suffix <suffix>] [<ssh arguments>...]`

		# List all targets and suppress project/target columns for compact output
		`ListSshTargets.fn.sh [--no-project-column] [--no-target-column] --all-targets [<ssh arguments>...]`

		# Print command help and exit
		`ListSshTargets.fn.sh --help`
