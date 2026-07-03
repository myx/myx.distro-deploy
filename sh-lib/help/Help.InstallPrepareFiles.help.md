📘 syntax: InstallPrepareFiles.fn.sh --project <project> --print-sync-folders|--print-clone-files|--print-script
📘 syntax: InstallPrepareFiles.fn.sh --project <project> --to-temp [<command> [<argument...>]]
📘 syntax: InstallPrepareFiles.fn.sh --project <project> [--save-script <fileName>] --to-directory <targetDirectory>
📘 syntax: InstallPrepareFiles.fn.sh [--help]

##  Summary:

		Builds deploy file preparation plans/scripts for a selected project and can print,
		save, or materialize prepared content.

##  Arguments:

		None. This command accepts no positional arguments; project is selected by --project.

##  Options:

		--project <project>
			Required in functional modes. Selects one project.

		--save-script <fileName>
			Saves generated script to a file path.

		--print-sync-folders
		--print-clone-tasks
		--print-clone-files
		--print-source-patch-scripts
		--print-target-patch-scripts
		--print-script
			Print-only modes for task/script inspection.

		--print-context-variables [<extra-args>...]
			Prints computed context variables used by install preparation.

		--to-directory <targetDirectory>
			Prepares/syncs files into target directory.

		--to-temp [<command> [<argument...>]]
			Prepares files in temp directory; optionally executes command in that directory.

		--to-deploy-output
			Prepares into standard deploy output path for selected project.

		--to-deploy-output-clean
			Rebuilds deploy output by syncing temp-prepared content with delete enabled.

		--help
			Prints command help and exits.

##  Examples:

		# Reference syntax for printing sync folders, clone files, or generated script.
		`InstallPrepareFiles.fn.sh --project <project> --print-sync-folders|--print-clone-files|--print-script`

		# Reference syntax for preparing into temp directory and optionally executing a follow-up command.
		`InstallPrepareFiles.fn.sh --project <project> --to-temp [<command> [<argument...>]]`

		# Show full help and option reference.
		`InstallPrepareFiles.fn.sh --help`

		# Compact print-mode syntax variant.
		`InstallPrepareFiles.fn.sh --project <project> --print-sync-folders/--print-clone-files/--print-script`

		# Compact temp-mode syntax variant with follow-up command.
		`InstallPrepareFiles.fn.sh --project <project> --to-temp <command> [<argument...>]`

		# Show folders that will be synchronized for selected project.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --print-sync-folders`

		# Show files that will be cloned/multiplied in prepare phase.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --print-clone-files`

		# Show source-path patch scripts used during preparation.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --print-source-patch-scripts`

		# Show target-path patch scripts used during preparation.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --print-target-patch-scripts`

		# Prepare into temp directory and inspect resulting web/default paths.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --to-temp find . | sort | grep web/default`

		# Prepare into temp directory and print resulting temp path.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --to-temp`

		# Prepare into temp directory and validate content by archiving it.
		`InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --to-temp tar czvf - . > /dev/null`

