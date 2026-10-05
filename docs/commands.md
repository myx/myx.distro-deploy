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
