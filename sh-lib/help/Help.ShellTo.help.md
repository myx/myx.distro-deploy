📘 syntax: ShellTo.fn.sh <project>
📘 syntax: ShellTo.fn.sh <unique-project-name-part>
📘 syntax: ShellTo.fn.sh <project-selector> [<ssh arguments>...]
📘 syntax: ShellTo.fn.sh [--help]

##  Summary:

		Opens remote shell for one resolved deploy target.

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

					# Open remote shell for a project using exact project path
				`ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org`

					# Open remote shell resolving project from a unique name fragment
				`ShellTo.fn.sh ndss113`

					# Run a single command on the remote host as a specific user
				`ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org -l mysql whoami`
		`ShellTo.fn.sh --help`
