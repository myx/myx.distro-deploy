📘 syntax: RebuildActionsFromDistro.fn.sh [--no-delete|--test1|--test2|--test3]
📘 syntax: RebuildActionsFromDistro.fn.sh [--help|--help-syntax]

##  Summary:

		Runs RebuildActions through deploy-aware distro context, so top-level action wrappers
		are regenerated for the active deploy environment.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--no-delete
			Keeps stale generated action files not present in
			current source index.

		--test1
		--test2
		--test3
			Flags, take no value. Internal test/debug discovery modes forwarded to
			RebuildActions.

		--help
			Prints command help and exits (no rebuild work is run).

		--help-syntax
			Prints syntax summary and exits.

##  Notes:

		Forwards options directly to RebuildActions.

##  Examples:

		# Rebuild actions and delete stale generated entries
		`RebuildActionsFromDistro.fn.sh`

		# Rebuild actions but keep stale entries
		`RebuildActionsFromDistro.fn.sh --no-delete`

		# Run discovery test mode 1 without rebuilding wrappers
		`RebuildActionsFromDistro.fn.sh --test1`
