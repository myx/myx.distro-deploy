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

					# Open local shell for a project using exact project path
				`LocalTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org`

					# Open local shell resolving project from a unique name fragment
				`LocalTo.fn.sh ndss113`

					# Run a single command in a project local context as a specific user
				`LocalTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org -l mysql whoami`
		`LocalTo.fn.sh --help`
