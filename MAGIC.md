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

## `--execute-command` is evaluated by the local shell, not the remote one

- The value is spliced unquoted into the ssh target line (`ExecuteParallel.fn.sh:130`) and the result is `eval`ed locally (`:205`/`:207`). Every metacharacter in it — `|`, `;`, `&`, redirections, globs, backticks, `$( )` — therefore expands and executes on the calling machine before ssh is reached.
- Quoting at the call site does not prevent it. The caller's quotes are consumed before the splice, so the command reaches it as bare words.
- **The failure reads as success.** `--execute-command 'echo <payload> | base64 -d | sh'` runs `ssh <host> echo <payload>` and then decodes and executes the payload on the caller, while the output still carries the remote hostname prefix. A fleet probe built that way reports a local answer as a fleet-wide one, and nothing in the output marks it. Measured, not assumed.
- Put `hostname` in any payload whose target has to be certain: a local execution is otherwise indistinguishable from a remote one.
- `--execute-stdin` and `--execute-script <local-path>` ship the body over the wire as stdin, correctly quoted (`:156`, `:169`). They are the forms for anything multi-line or carrying a metacharacter; `--execute-command` is for one simple command with none.

## The `Deploy` verb reuses the function already loaded

- `Deploy <Tool> ...` sources `sh-scripts/<Tool>.fn.sh` only when that function is not yet defined in the session. When it is defined, the loaded copy runs and nothing reports that the file was skipped.
- After editing a tool's own source, invoke `<Tool>.fn.sh` directly — executing the file redefines the function. `Deploy ExecuteParallel ...` keeps running the pre-edit copy for the rest of the session.

## `DeployConsole.include`'s prompt hook applies nothing

- The `--shell-prompt` arm reads `MDSC_INT_CD`, `cd`s to it and clears it, and cannot change the console's working directory: the `Deploy()` wrapper sources this include inside `( … )` and `PROMPT_COMMAND` calls that wrapper inside `$( … )`, so both statements run two subshells below the interactive shell. The arm announces the change on stderr before applying nothing, which is why it reads as working.
- Full finding, with both controls and the boundary of what was measured: `myx.distro-.local/MAGIC.md`, "The prompt hook announces a change it cannot apply" — read there, not duplicated here.

## Exit status is not a deploy result

- `DeployProjectSsh.fn.sh` can print an SSH failure to stderr and still return 0.
- Gate on the artifact: `DeployProjectSsh.fn.sh --print-installer` emitting the expected content is the real pre-deploy check.

## Cross-workspace invocation and TTY requirements

- **A `Distro*Console.sh` honours an ambient `MMDAPP`, and derives one from its own location only when `MMDAPP` is unset or names no directory.** That guard is emitted by each of the five per-package console generators, and reads as `DistroDeployConsole.sh:5-7` in a generated workspace root. So a caller already scoped to one workspace that runs a second workspace's console gets the second workspace's tooling pointed at the first one's source tree: `ScanSourceProjects.include: no source folder!`, then "No matching projects found" for projects that plainly exist. An `MMDAPP` naming a real directory that is not a workspace fails loud instead, on the missing `.local`. Measured both ways — inherited, the second console reports the first workspace; cleared, it reports its own.
- That is what the `mcp__myx_distro__execute` MCP tool's apparent pinning to its own workspace root actually is: the tool exports its own `MMDAPP`, so a `cd` prefix inside the command string moves nothing. Switching to a different execution tool is not the fix, and does not address the same behaviour reached any other way. Either pass that tool's own `workspace` argument, which starts a fresh process with `MMDAPP` moved and the index caches dropped, or clear the inherited environment: `cd <other-workspace> && env -u MMDAPP -u MDSC_CACHED -u MDSC_SOURCE -u MDSC_OUTPUT -u MDSC_OPTION -u MDSC_INMODE sh -c './DistroDeployConsole.sh --non-interactive'`.
- `ScreenTo.fn.sh` requires a real TTY. It resolves the project and the SSH connection correctly, then fails with "Must be connected to a terminal" when run from a non-interactive/pty-less caller. For a single non-interactive remote command, use `ShellTo.fn.sh` instead.
- A multi-word remote command for `ShellTo` is passed as trailing bare words after a literal `--` (e.g. `ShellTo <selector> --ssh-user root -- ae3 status`). `--execute-stdin`, `--execute-script <path>` and `--execute-command <command>` are `ShellTo`'s own modes, read only at the position directly after the project selector. `--display-targets` is an `ExecuteParallel`/`ExecuteSequence` option and `ShellTo` does not take it. A mode written at any other position, and `--display-targets` anywhere, is silently folded into the remote-command tokens, surfacing as a confusing `ssh: illegal option` three layers downstream.
- Piping a script to `ShellTo <selector> -- bash` (or `sh`) as the remote command works well and is a common pattern — `ShellTo` defaults to exactly this (`-t '\`command -v bash || command -v sh\`'`) when no trailing command is given at all. **Contradicted in part:** the default-command clause does not hold — see `ShellTo`'s `-t` default command never fires below. `${extraArguments:-$defaultCommand}` never reaches the default in this tool, so no remote pty is requested and the bare form aborts on the remote tty guard instead. Open, not yet fixed.

## `ShellTo`'s `-t` default command never fires

- `ShellTo.fn.sh` builds `extraArguments` with `printf '%q ' "$@"`. With zero arguments bash still applies the format once, so the result is `''` followed by a space — three characters, not an empty string. `${extraArguments:-$defaultCommand}` therefore always takes the built value and the default is never reached.
- `-t` requests no remote pty of its own as a result. An interactive payload needs the tty requested through trailing ssh arguments; without one the remote side aborts on its own tty guard.
- `ScreenTo.fn.sh` builds the same variable with a `for` loop over `"$@"`, which yields a genuinely empty string for zero arguments, so its own `-t` default does fire. The two tools differ in this one construction, and a statement about either is never a statement about both.
- Open, not yet fixed.

## The remote guard precedes the first filesystem touch

- The emitted payload runs its tty guard before it creates any directory, so a guard abort leaves the host untouched.
- The unpack directory is created before the cleanup trap is armed, so a failure in that window leaves the directory behind.

## The generated installer carries two inert shebangs

- `InstallPrepareScript.fn.sh:146-151` embeds each hooked body into the aggregate as `( eval "$( cat << 'BLK_<cksum>' … )" )`. A shebang inside one of those bodies is data, never an interpreter line.
- `InstallPrepareScript.fn.sh:96` writes `#!/bin/sh` as the aggregate's own first line, and `DeployProjectSsh.fn.sh:333` emits `bash ./exec`, which overrides it. So both shebangs are inert, and the aggregate's own is the one a careful reader would otherwise trust.
- The real interpreter for those bodies is bash. `reference/shell.md` in `magic-developer` states which standard follows from that.
- The discriminator is the mechanism, not a count: a file installed as a real executable under `data/**` runs under its own shebang; a body hooked in through `image-install:exec-update-*:host/install/*.txt` does not. Read how a file is executed before deciding which standard it is held to.
- Open, not yet fixed: `DeployProjectSsh.fn.sh:333` emits `bash ./exec` unconditionally while the generated file declares `#!/bin/sh`, so a target carrying no bash fails at the last step.
