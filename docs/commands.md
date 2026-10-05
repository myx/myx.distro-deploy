# Commands

[Back to the README](../README.md)

Pick the narrowest tool that fits the job.

- Look before you connect:
	- `ListSshTargets.fn.sh` — report what a selector resolves to. Acts on nothing.
- Reach one target:
	- `ShellTo.fn.sh` — open a shell on exactly one target.
	- `ScreenTo.fn.sh` — open a remote `screen` session on one target.
	- `LocalTo.fn.sh` — enter a project-local session for one resolved target.
	- `Reinstall.fn.sh` — reconnect to one target and run its reinstall flow.
- Reach many targets:
	- `ExecuteSequence.fn.sh` — run a command or script across many targets, one at a time.
	- `ExecuteParallel.fn.sh` — run it across many targets in parallel.
	- `ExecuteInteractive.fn.sh` — run it interactively against selected targets.
- Deploy a project:
	- `DeployProjectSsh.fn.sh` — build, print, save or run one project's deploy scripts.
	- `InstallPrepareFiles.fn.sh` — build a project's file-preparation plan; print, save or materialise it.
	- `InstallPrepareScript.fn.sh` — build a project's install patch-script bundle.
- Maintain the workspace:
	- `RebuildActionsFromDistro.fn.sh` — regenerate workspace actions for the active deploy environment.
	- `RebuildKnownHostsFromDistro.fn.sh` — regenerate workspace `ssh/known_hosts`.
	- `DistroDeployTools.fn.sh` — re-create the deploy console launcher, set workspace options, upgrade deploy tools.


## Option reference

Every `--ssh-*` option overrides one SSH value in the generated command line. The last value wins. The overrides are `--ssh-name`, `--ssh-host`, `--ssh-port`, `--ssh-user`, `--ssh-home` and `--ssh-args`.

- `ListSshTargets.fn.sh <project-selector>` or `ListSshTargets.fn.sh --all-targets`
	- `--select-from-env` — use `MDSC_SELECT_PROJECTS` as the selection.
	- `--line-prefix <prefix>` and `--line-suffix <suffix>` — wrap each output line.
	- `--no-project-column` and `--no-target-column` — drop a column from each row.
- `ShellTo.fn.sh <project-selector> [<ssh arguments>...]` — the selector must resolve to exactly one target.
	- `--execute-stdin` — read a script body from stdin until end of file and pipe it to the target.
	- `--execute-script <script-name>` — send a script file. The path is relative to the workspace `source` directory. A missing file exits 1.
	- `--execute-command <command>` — run one command. It is the same as passing the command as trailing words.
	- Write the execute option directly after the selector. Anything before the selector is read as an `--ssh-*` override.
- `ExecuteSequence.fn.sh` and `ExecuteParallel.fn.sh <project-selector>`
	- `--all-targets` — use every deploy target.
	- `--select-from-env` — use `MDSC_SELECT_PROJECTS`.
	- `--no-sleep` — skip the delay before execution.
	- `--non-interactive` — hide the task explanation and skip the delay.
	- `--execute-stdin`, `--execute-script <script-name>`, `--execute-command <command>` — pick what runs on each target.
	- `--execute-post-process <command>` — process the combined output stream. `ExecuteParallel.fn.sh` only.
	- `--display-targets` — print the resolved targets.
- `DeployProjectSsh.fn.sh --project <project>`
	- `--prepare-exec`, `--prepare-sync`, `--prepare-full`, `--prepare-none` — choose the prepare step. The last one wins.
	- `--deploy-sync`, `--deploy-exec`, `--deploy-full`, `--deploy-none` — choose what runs on the targets. `--deploy-none` returns success after parsing.
	- `--print-files`, `--print-sync-tasks`, `--print-deploy-patch-scripts`, `--print-context-variables`, `--print-installer`, `--print-ssh-targets` — inspect, and change nothing.
	- `--print-sync-script`, `--print-exec-script`, `--print-full-script` — print the generated script.
	- `--save-sync-script`, `--save-exec-script`, `--save-full-script` — save it to the deploy output cache and print the path.
	- `--match <install-script-filter>` — limit the install patch scripts in the installer.
	- `--use-gzip`, `--use-bzip2`, `--use-xz` — pick the compression for the transfer. `--use-gz` and `--use-bz2` are short forms.
- `Reinstall.fn.sh <project> [<ssh arguments>...]` — the project must resolve to exactly one target.


## Manuals

Each tool has a manual with its full syntax, options and examples.

- [DeployProjectSsh](../sh-lib/help/Help.DeployProjectSsh.help.md)
- [DistroDeployTools](../sh-lib/help/Help.DistroDeployTools.help.md)
- [ExecuteInteractive](../sh-lib/help/Help.ExecuteInteractive.help.md)
- [ExecuteParallel](../sh-lib/help/Help.ExecuteParallel.help.md)
- [ExecuteSequence](../sh-lib/help/Help.ExecuteSequence.help.md)
- [InstallPrepareFiles](../sh-lib/help/Help.InstallPrepareFiles.help.md)
- [InstallPrepareScript](../sh-lib/help/Help.InstallPrepareScript.help.md)
- [ListSshTargets](../sh-lib/help/Help.ListSshTargets.help.md)
- [LocalTo](../sh-lib/help/Help.LocalTo.help.md)
- [RebuildActionsFromDistro](../sh-lib/help/Help.RebuildActionsFromDistro.help.md)
- [RebuildKnownHostsFromDistro](../sh-lib/help/Help.RebuildKnownHostsFromDistro.help.md)
- [Reinstall](../sh-lib/help/Help.Reinstall.help.md)
- [ScreenTo](../sh-lib/help/Help.ScreenTo.help.md)
- [ShellTo](../sh-lib/help/Help.ShellTo.help.md)
- [DeployProjects, an unfinished draft](../sh-lib/help/Help.DeployProjects%28Unfinished%29.help.md)
