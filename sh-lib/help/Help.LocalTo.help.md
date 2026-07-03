📘 syntax: LocalTo.fn.sh <project>
📘 syntax: LocalTo.fn.sh <unique-project-name-part>
📘 syntax: LocalTo.fn.sh <project-selector> [<command-or-ssh-args>...]
📘 syntax: LocalTo.fn.sh [--help]

##  Summary:

		Enters project-local shell/session for one resolved deploy target.

##  Arguments:

		project-selector
			Required positional argument at position 1. Must resolve to exactly one target.

		command-or-ssh-args
			Optional positional tail (position 2+). Passed to target command resolver.

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

##  Notes:

		If no command tail is provided, default command is local shell path resolution.

##  Examples:

				# Open local shell for the exact project name
		`LocalTo.fn.sh <project>`

				# Resolve project by unique name fragment and open local shell
		`LocalTo.fn.sh <unique-project-name-part>`

				# Print command help and exit
		`LocalTo.fn.sh --help`
