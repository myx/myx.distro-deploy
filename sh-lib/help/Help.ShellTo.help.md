📘 syntax: ShellTo.fn.sh <project>
📘 syntax: ShellTo.fn.sh <unique-project-name-part>
📘 syntax: ShellTo.fn.sh <project-selector> [<ssh arguments>...]
📘 syntax: ShellTo.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]
📘 syntax: ShellTo.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]
📘 syntax: ShellTo.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]
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

		--execute-stdin
			Executes stdin body on the resolved target. Written at position 2,
			directly after the project selector. Prompts on stderr, reads the
			body until EOF, then pipes it into the target connection's stdin.

		--execute-script <script-name>
			Executes script file content on the resolved target. Written at
			position 2, directly after the project selector. The path is taken
			relative to the workspace `source` directory; a missing file exits 1.

		--execute-command <command>
			Executes command string on the resolved target. Written at position 2,
			directly after the project selector. Equivalent to passing the same
			command as the trailing positional tail.

		--help
			Prints command help and exits.

##  Examples:

		# Open remote shell for a project using exact project path
		`ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org`

		# Open remote shell resolving project from a unique name fragment
		`ShellTo.fn.sh ndss113`

		# Run a single command on the remote host as a specific user
		`ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org -l mysql whoami`

		# Run a single command on the remote host, stated as a mode
		`ShellTo.fn.sh ndss113 --execute-command 'uname -a'`

		# Pipe a script body to the remote host, typed or redirected on stdin
		`ShellTo.fn.sh ndss113 --execute-stdin`

		# Send a script file from the workspace source tree to the remote host
		`ShellTo.fn.sh ndss113 --execute-script ndm/cloud.knt/setup.host-ndss113/host/install/setup.txt`

		# Print command help and exit
		`ShellTo.fn.sh --help`

##  Notes:

		Resolves the selector to exactly one target. A selector matching nothing exits 1.
		A selector matching more than one prints the matching targets and exits 2 without
		connecting to any of them.

		Use ListSshTargets to see what a selector resolves to before acting on it.

		The execute-mode flag is written directly after the project selector, and
		SSH arguments follow it. Anything placed before the selector is parsed as
		an --ssh-XXXX override only.

		--execute-command composes the command into the target command line, where
		the local shell expands it before SSH is reached. --execute-stdin and
		--execute-script ship the body over the wire instead, and are the forms for
		anything multi-line or carrying a metacharacter.

		--execute-stdin and --execute-script request no remote pseudo-terminal.
