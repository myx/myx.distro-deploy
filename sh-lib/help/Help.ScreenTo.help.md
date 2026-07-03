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

		# Attach to screen session for a project using exact project path
		`ScreenTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org`

		# Attach to screen session resolving project from a unique name fragment
		`ScreenTo.fn.sh ndss113`

		# Attach to screen session as a specific SSH user
		`ScreenTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org -l mysql`

		# Print command help and exit
		`ScreenTo.fn.sh --help`
