📘 syntax: ScreenTo.fn.sh <project>
📘 syntax: ScreenTo.fn.sh <unique-project-name-part>
📘 syntax: ScreenTo.fn.sh <project-selector> [<ssh arguments>...]
📘 syntax: ScreenTo.fn.sh [--help]

##  Summary:

		Opens remote screen session (with shell fallback) for one resolved deploy target.

##  Arguments:

		project-selector
			Required positional argument at position 1. Must resolve to exactly one target.

		ssh-arguments
			Optional positional tail (position 2+). Forwarded to SSH command composition.

##  Options:

		--ssh-name <name>
		--ssh-host <host>
		--ssh-port <port>
		--ssh-user <user>
		--ssh-home <path>
		--ssh-args <args>
			Optional SSH overrides. For duplicates, last value wins.

		--help
			Prints command help and exits.

##  Examples:

				# Attach to project screen session using exact project name
		`ScreenTo.fn.sh <project>`

				# Attach using a unique project name fragment when full name is long
		`ScreenTo.fn.sh <unique-project-name-part>`

				# Print command help and exit
		`ScreenTo.fn.sh --help`
