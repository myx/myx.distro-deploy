# MAGIC.md — myx.distro-deploy

Team-owned notes for the magic-* team.

## Pick the narrowest tool that fits

- A narrow tool refuses a selector that matches more than it should. A fan-out tool executes against every target the selector matched.
- `ListSshTargets.fn.sh` — answers what a selector actually resolves to. Run it before acting on a selector.
- `ShellTo.fn.sh` — exactly one target. Resolving to none returns 1; resolving to more than one prints the matches and returns 2 without connecting to any of them.
- `ExecuteSequence.fn.sh` — many targets, one after another.
- `ExecuteParallel.fn.sh` — many targets at once as background jobs; `--execute-post-process` handles the combined stream.
- A single-host read is `ShellTo` work.
- A workspace may legitimately declare no deploy targets. A command that resolves nothing has found nothing to act on, which is not evidence of broken tooling — check whether the workspace declares any targets before investigating the tool.

## Argument order is load-bearing on the Execute* tools

- Every `--ssh-*`, `--no-sleep`, `--non-interactive` and `--execute-post-process` option comes before `--execute-command`/`--execute-script`/`--execute-stdin`/`--display-targets`.
- The option parser stops at the first token it does not recognise, so anything placed after the execute-type flag leaks onto the end of the remote command line instead of being parsed.

## The `Deploy` verb reuses the function already loaded

- `Deploy <Tool> ...` sources `sh-scripts/<Tool>.fn.sh` only when that function is not yet defined in the session. When it is defined, the loaded copy runs and nothing reports that the file was skipped.
- After editing a tool's own source, invoke `<Tool>.fn.sh` directly — executing the file redefines the function. `Deploy ExecuteParallel ...` keeps running the pre-edit copy for the rest of the session.

## Exit status is not a deploy result

- `DeployProjectSsh.fn.sh` can print an SSH failure to stderr and still return 0.
- Gate on the artifact: `DeployProjectSsh.fn.sh --print-installer` emitting the expected content is the real pre-deploy check.
