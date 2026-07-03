📘 syntax: InstallPrepareScript.fn.sh --project <project> [--match <name>...] --print-files|--print-script
📘 syntax: InstallPrepareScript.fn.sh --project <project> [--match <name>...] --to-file <targetFile>
📘 syntax: InstallPrepareScript.fn.sh [--help]

##  Summary:

		Builds install patch script bundles for selected project scripts.

##  Arguments:

		None. This command accepts no positional arguments; project is selected by --project.

##  Options:

		--project <project>
			Required in functional modes. Selects one project.

		--match <name>
			Optional filter for script names/paths. Can be provided multiple times.

		--print-files
			Prints selected install script file paths.

		--print-install-context-variables [<extra-args>...]
			Prints install context variables.

		--print-script
			Prints generated combined installer script.

		--to-file <targetFile>
			Writes generated installer script to target file.

		--help
			Prints command help and exits.

##  Examples:

		# Reference syntax for printing file list or generated installer script.
		`InstallPrepareScript.fn.sh --project <project> [--match <name>...] --print-files|--print-script`

		# Reference syntax for writing generated installer script to file.
		`InstallPrepareScript.fn.sh --project <project> [--match <name>...] --to-file <targetFile>`

		# Show full help and option reference.
		`InstallPrepareScript.fn.sh --help`

		# Compact print-mode syntax variant.
		`InstallPrepareScript.fn.sh --project <project> [--match <name>...] --print-files/--print-script`

		# Compact to-file syntax variant.
		`InstallPrepareScript.fn.sh --project <project> [--match <name>...] --to-file <targetDirectory>`

		# Generate and print full installer script for selected project.
		`InstallPrepareScript.fn.sh --project ndm/cloud.knt/setup.host-ndss112r3.example.org --print-script`

		# Generate installer script filtered to monit-related patches.
		`InstallPrepareScript.fn.sh --project ndm/cloud.knt/setup.host-ndss112r3.example.org --match monit --print-script`

		# Print files selected for installer generation.
		`InstallPrepareScript.fn.sh --project prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --print-files`

		# Generate and print full installer script for selected project.
		`InstallPrepareScript.fn.sh --project prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --print-script`

