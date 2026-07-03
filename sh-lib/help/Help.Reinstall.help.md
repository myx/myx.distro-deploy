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

					# Reinstall a project on its remote target
				`Reinstall.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org`

					# Reinstall with additional SSH arguments (user, port, key, etc.)
				`Reinstall.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org [<ssh arguments>...]`
		`Reinstall.fn.sh --help`
