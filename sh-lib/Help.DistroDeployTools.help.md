📘 syntax: DistroDeployTools.fn.sh <option>
📘 syntax: DistroDeployTools.fn.sh [--help]

##  Options:

		--upgrade-deploy-tools
			Upgrades local deploy packages with latest `master` version.

		--system-config-option <arguments...>
		--custom-config-option <arguments...>
			Sets the workspace environment parameter. 'system' is common for workspace and
			'custom' is for current workspace user.

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

			Following options are defined (list of basic ones, option names are not limited
			to this list, but these options are actively used by scripts of this package):

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

		--make-console-command [--quiet]
			Re-Creates DistroDeployConsole.sh script to be used as a command to quickly enter workspace
			console.

			Won't output helpful information on files created and how to use those files, when
			`--quiet` option specified.

		--make-workspace-integration-files [--quiet]
			Runs all `--make-*` commands, (re-)creating all workspace integration files.

			Won't output helpful information on files created and how to use those files, when
			`--quiet` option specified.

##  Examples (in Local Console, within workspace context):

		# Upgrade deploy tooling from local installer scripts
		`DistroDeployTools.fn.sh --upgrade-deploy-tools`

		# Show deploy tools help
		`DistroDeployTools.fn.sh --help`

##  Examples (in OS default shell):

		# Show deploy tools help from the OS shell
		`bash .local/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh --help`

		# Upgrade deploy tooling from the OS shell
		`bash .local/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh --upgrade-deploy-tools`
