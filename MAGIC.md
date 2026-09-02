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

## Cross-workspace invocation and TTY requirements

- The `mcp__myx_distro__execute` MCP tool stays pinned to its own configured workspace root. A `cd` prefix inside the command string does not move `Deploy`'s project-selection context (`Deploy --info`'s `MMDAPP ROOT`) to a different workspace, so every selector against that other workspace's projects resolves to none. To run a `Distro*Console.sh` against a workspace other than the MCP tool's own configured root, invoke it through a plain shell-execution tool with an explicit `cd` instead.
- `ScreenTo.fn.sh` requires a real TTY. It resolves the project and the SSH connection correctly, then fails with "Must be connected to a terminal" when run from a non-interactive/pty-less caller. For a single non-interactive remote command, use `ShellTo.fn.sh` instead.
- A multi-word remote command for `ShellTo` is passed as trailing bare words after a literal `--` (e.g. `ShellTo <selector> --ssh-user root -- ae3 status`) — `--execute-command`/`--execute-script`/`--execute-stdin`/`--display-targets` are `ExecuteParallel`/`ExecuteSequence` options, not `ShellTo`'s at all. `ShellTo.fn.sh` now rejects those four with a clear error naming the trailing-`--` form; previously it silently folded the unrecognized flag into the remote-command tokens, surfacing as a confusing `ssh: illegal option` three layers downstream instead.
- Piping a script to `ShellTo <selector> -- bash` (or `sh`) as the remote command works well and is a common pattern — `ShellTo` defaults to exactly this (`-t '\`command -v bash || command -v sh\`'`) when no trailing command is given at all. **Contradicted in part:** the default-command clause does not hold — see `ShellTo`'s `-t` default command never fires below. `${extraArguments:-$defaultCommand}` never reaches the default in this tool, so no remote pty is requested and the bare form aborts on the remote tty guard instead. Open, not yet fixed.

## `ShellTo`'s `-t` default command never fires

- `ShellTo.fn.sh` builds `extraArguments` with `printf '%q ' "$@"`. With zero arguments bash still applies the format once, so the result is `''` followed by a space — three characters, not an empty string. `${extraArguments:-$defaultCommand}` therefore always takes the built value and the default is never reached.
- `-t` requests no remote pty of its own as a result. An interactive payload needs the tty requested through trailing ssh arguments; without one the remote side aborts on its own tty guard.
- `ScreenTo.fn.sh` builds the same variable with a `for` loop over `"$@"`, which yields a genuinely empty string for zero arguments, so its own `-t` default does fire. The two tools differ in this one construction, and a statement about either is never a statement about both.
- Open, not yet fixed.

## The remote guard precedes the first filesystem touch

- The emitted payload runs its tty guard before it creates any directory, so a guard abort leaves the host untouched.
- The unpack directory is created before the cleanup trap is armed, so a failure in that window leaves the directory behind.
