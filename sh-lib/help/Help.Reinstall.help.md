📘 syntax: Reinstall.fn.sh <project> [<ssh arguments>...]
📘 syntax: Reinstall.fn.sh [--help]

##  Summary:

		Reconnects to one deploy target and runs reinstall/login flow.

##  Arguments:

		project
			Required positional argument at position 1. Must resolve to exactly one target.

		ssh-arguments
			Optional positional tail (position 2+). Forwarded to target resolver.

##  Options:

		--help
			Prints command help and exits.

##  Notes:

		Internal recursion uses --connect-ssh and --check-count; these are internal and not
		intended as user-facing CLI options.

##  Examples:

				# Reinstall project on remote target using default SSH settings
		`Reinstall.fn.sh <project> [<ssh arguments>...]`

				# Reinstall project while passing additional SSH options (port, key, proxy, etc.)
		`Reinstall.fn.sh <project> [<ssh arguments>...]`

				# Print command help and exit
		`Reinstall.fn.sh --help`
