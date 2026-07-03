📘 syntax: RebuildKnownHostsFromDistro.fn.sh [--no-delete]
📘 syntax: RebuildKnownHostsFromDistro.fn.sh [--help|--help-syntax]

##  Summary:

		Runs RebuildKnownHosts through deploy-aware distro context, so workspace known_hosts
		is rebuilt for the active deploy environment.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--no-delete
			Keeps stale known_hosts lines not present in current
			source set.

		--help
			Prints command help and exits (no known_hosts rebuild is
			run).

		--help-syntax
			Prints syntax summary and exits.

##  Notes:

		Forwards options directly to RebuildKnownHosts.

##  Examples:

		# Rebuild workspace known_hosts from project known_hosts files
		`RebuildKnownHostsFromDistro.fn.sh`

		# Rebuild known_hosts but keep stale records
		`RebuildKnownHostsFromDistro.fn.sh --no-delete`
