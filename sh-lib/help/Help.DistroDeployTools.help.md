📘 syntax: DistroDeployTools.fn.sh --make-workspace-integration-files [--quiet]
📘 syntax: DistroDeployTools.fn.sh --make-console-command [--quiet]
📘 syntax: DistroDeployTools.fn.sh --make-console-script
📘 syntax: DistroDeployTools.fn.sh --{system|custom}-config-option <operation>
📘 syntax: DistroDeployTools.fn.sh --upgrade-deploy-tools
📘 syntax: DistroDeployTools.fn.sh [--help|--help-syntax]

##  Summary:

		Deploy-side workspace tooling entrypoint for deploy make helpers, config updates,
		and deploy tools upgrade flow.

##  Arguments:

		None. This command is option-driven.

##  Options:

		--make-workspace-integration-files [--quiet]
			Runs all relevant `--make-*` commands, (re-)creating all workspace
			integration files and exits.

			Won't output helpful information on files created and how to use those files,
			when `--quiet` option specified.

		--make-console-command [--quiet]
			Re-Creates DistroDeployConsole.sh script to be used as a command to quickly
			enter workspace console and exits.

			Won't output helpful information on files created and how to use those files,
			when `--quiet` option specified.

		--make-console-script
			Prints deploy console script body (used by --make-console-command) and exits.

		--system-config-option <arguments...>
		--custom-config-option <arguments...>
			Sets the workspace environment parameter. 'system' is common for workspace and
			'custom' is for current workspace user. Performs requested config operation and exits.

			Following operations (arguments) are supported:

				--select <option-name>
				--select-default <option-name> <default-value>
					Reads one or all variables. If value is not set, default-value is returned.

				--select --all
				--select-all
					Reads all variables.

				--upsert <option-name> <value>
				--upsert-if <option-name> <value> <if-value>
					Sets a variable. Optionally, sets variable only if it's current value
					is set to given value.

				--delete <option-name>
				--delete-if <option-name> <if-value>
					Deletes a variable. Optionally, deletes the variable only if it's value
					is set to given value.

			Shared config variables (implemented in LocalTools.Config.include and consumed
			across distro consoles):

				MDLT_CONSOLE_ORIGIN
					Supports values of ".local", "source" or absolute path to whatever workspace's
					".local" or "source" directory. This parameter is used (with some extra sanity
					checks) while detecting MDLT_ORIGIN context value.

				MDLT_CONSOLE_SCRIPT
					Shell script to include in console initialisation process. Allows to setup
					extra commands or settings. Note: before including this script, $HOME/.bashrc
					will be included automatically, if present.

				MDLT_CONSOLE_HISTORY
					Defines where and how your interactive shell (Console) history is stored. The
					default setting is `workspace-personal`.

					Supported values:
					– workspace-personal: each user gets their own file under <workspace>/.local/home/$USER/.bash_history;
					– local-machine-home: write to a per-workspace file in $HOME (e.g. ~/.bash_history_<workspace>);
					– workspace-separate: each user gets separate own history files, one per each subsystem (if ant)
						under <workspace>/.local/home/$USER/.bash_history_{source,deploy,remote};
					– workspace-shared: everyone shares a single history at <workspace>/.local/.common_bash_history;
					– bash-default: same as user-default, explicitly resets to Bash's standard ~/.bash_history;
					– user-default: leave history in the user's default (whatever settings currently are, untouched).

					Based on this setting the scripts configure HISTFILE along with HISTCONTROL,
					HISTSIZE, HISTFILESIZE and histappend to achieve the desired isolation or
					sharing.

				MDLT_ACTIONS_SH_WRAP
					Shell command to wrap shell actions to execute. Allows to run actions on
					remote runner machine or add extra logging/notification, etc...

		--upgrade-deploy-tools
			Runs DistroLocalTools.fn.sh --install-distro-deploy and exits.

		--help
			Prints command help and exits.

		--help-syntax
			Prints syntax summary and exits.

##  Environment Variables:

		Context variables used in deploy mode:

			MMDAPP
				Workspace root path.

			MDLT_ORIGIN
				Source root for distro command libraries and scripts.

			MDSC_INMODE
				Current console mode (deploy).

			MDSC_OPTION
				Current context option set (for example distro input mode).

			MDSC_SOURCE
				Current source path for deploy preparation/install flows.

			MDSC_CACHED
				Current cached metadata/index root path.

			MDSC_OUTPUT
				Current output/deploy target root path.

			MDSC_DETAIL
				Debug verbosity control (<empty>, true, full).

##  Examples (in Local Console, within workspace context):

		# Re-create deploy console launcher command
		`DistroDeployTools.fn.sh --make-console-command`

		# Upgrade deploy tooling from local installer scripts
		`DistroDeployTools.fn.sh --upgrade-deploy-tools`

		# Print all configured deploy-tool options
		`DistroDeployTools.fn.sh --system-config-option --select-all`

##  Examples (in OS default shell):

		# Show DistroDeployTools help from the OS shell
		`bash .local/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh --help`

		# Upgrade deploy tooling from the OS shell
		`bash .local/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh --upgrade-deploy-tools`
