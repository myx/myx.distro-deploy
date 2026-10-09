# MAGIC.md — myx.distro-deploy

Team-owned notes for the magic-* team.

## Goal and where things live

- The package installs a built distro image onto SSH targets. It owns the `image-process` and `image-install` stages ([Formats](docs/formats.md)). `project.inf` requires `myx/myx.distro-source`.
- `sh-scripts/` holds the target tools (`ListSshTargets`, `ShellTo`, `Execute*`) and the deploy tools (`DeployProjectSsh`, `InstallPrepare*`).
- `sh-lib/lib.distro-image.include` defines `DistroSshConnect`, which the `ShellTo` and `Execute*` tools call.
- `sh-lib/ImageDeploy.{prefix,suffix}.include` and `sh-lib/ImagePrepareFiles.{prefix,suffix}.include` are the prefix and suffix parts of the generated scripts.
- `builders/` holds this package's pipeline builders. `make/` holds the `pack.*.inf` files.
- `sh-test/ImageDeployRemoteStatusCheck.test.sh` is the package's one test rig.

## Pick the narrowest tool that fits

- A narrow tool refuses a selector that matches more than it should. A fan-out tool executes against every target the selector matched.
- Which tool fits which job, and what each one returns: [Commands](docs/commands.md) and [Troubleshooting](docs/troubleshooting.md). Run `ListSshTargets.fn.sh` before acting on a selector.
- A single-host read is `ShellTo` work.
- A workspace may legitimately declare no deploy targets. A command that resolves nothing has found nothing to act on, which is not evidence of broken tooling.

## Argument order is load-bearing on the Execute* tools

- The option parser stops at the first token it does not recognise, so anything placed after the execute-type flag leaks onto the end of the remote command line instead of being parsed. The user-facing rule: [Troubleshooting](docs/troubleshooting.md).

## `--execute-command` is quoted for the remote shell

- `ExecuteParallel.fn.sh:130`, `ExecuteSequence.fn.sh:120` and `ShellTo.fn.sh:89` pass the value through `printf '%q'` before it reaches the ssh line. The comment beside each states why: the local `eval` and `DistroSshConnect` each strip one layer, so only the remote shell parses the command.
- Keep both layers when changing any of these call sites. Removing one makes the local shell expand the command's metacharacters before ssh is reached.
- `--execute-stdin` and `--execute-script <local-path>` ship the body over the wire as stdin (`ExecuteParallel.fn.sh:157`, `:170`). They are the forms for anything multi-line.

## The `Deploy` verb reuses the function already loaded

- `Deploy <Tool> ...` sources `sh-scripts/<Tool>.fn.sh` only when that function is not yet defined in the session. When it is defined, the loaded copy runs and nothing reports that the file was skipped. User-facing note: [Troubleshooting](docs/troubleshooting.md).

## `DeployConsole.include`'s prompt hook applies nothing

- The `--shell-prompt` arm reads `MDSC_INT_CD`, `cd`s to it and clears it, and cannot change the console's working directory: the `Deploy()` wrapper sources this include inside `( … )` and `PROMPT_COMMAND` calls that wrapper inside `$( … )`, so both statements run two subshells below the interactive shell. The arm announces the change on stderr before applying nothing, which is why it reads as working.
- Full entry: `myx.distro-.local/MAGIC.md`, "The prompt hook announces a change it cannot apply" — read there, not duplicated here.

## Exit status is not a deploy result

- `DeployProjectSsh.fn.sh` can print an SSH failure to stderr and still return 0. The user-facing check: [Troubleshooting](docs/troubleshooting.md).
- The remote script ends with `bash ./exec`, and the rsync lines sit in a `| tee` pipeline. The client reports the real `exec` status and checks `PIPESTATUS[0]` after each rsync. Each install fragment runs as its own `set -e` subshell. When the log is the only evidence, look for `deploy fragment failed: <name>`.

## Cross-workspace invocation and TTY requirements

- **A `Distro*Console.sh` honours an ambient `MMDAPP`, and derives one from its own location only when `MMDAPP` is unset or names no directory.** That guard is emitted by each per-package console generator, and reads as `DistroDeployConsole.sh:5` in a generated workspace root. An `MMDAPP` naming a real directory that is not a workspace fails loud instead, on the missing `.local`. Symptom and fix: [Troubleshooting](docs/troubleshooting.md).
- The `mcp__myx_distro__execute` MCP tool exports its own `MMDAPP`, so a `cd` prefix inside the command string moves nothing. Either pass that tool's own `workspace` argument, which starts a fresh process with `MMDAPP` moved and the index caches dropped, or clear the inherited environment as the troubleshooting page shows. Switching to a different execution tool does not change this behaviour.
- `ScreenTo` TTY needs and `ShellTo` argument positions: [Troubleshooting](docs/troubleshooting.md).
- Piping a script to `ShellTo <selector> -- bash` (or `sh`) as the remote command works. With no trailing command at all, `ShellTo` does not reach its own default — see the next entry.

## `ShellTo`'s `-t` default command never fires

- `ShellTo.fn.sh` builds `extraArguments` with `printf '%q ' "$@"`. With zero arguments bash still applies the format once, so the result is `''` followed by a space — three characters, not an empty string. `${extraArguments:-$defaultCommand}` therefore always takes the built value and the default is never reached.
- `-t` requests no remote pty of its own as a result. An interactive payload needs the tty requested through trailing ssh arguments; without one the remote side aborts on its own tty guard.
- `ScreenTo.fn.sh` builds the same variable with a `for` loop over `"$@"`, which yields a genuinely empty string for zero arguments, so its own `-t` default does fire. The two tools differ in this one construction, and a statement about either is never a statement about both.
- Open, not yet fixed.

## The remote guard precedes the first filesystem touch

- The emitted payload runs its tty guard before it creates any directory, so a guard abort leaves the host untouched.
- The unpack directory is created before the cleanup trap is armed, so a failure in that window leaves the directory behind.

## The generated installer carries two inert shebangs

- `InstallPrepareScript.fn.sh:146-150` embeds each hooked body into the aggregate as `( set -e ; eval "$( cat << '<hash>' … )" )`. A shebang inside one of those bodies is data, never an interpreter line.
- `InstallPrepareScript.fn.sh:96` writes `#!/bin/sh` as the aggregate's own first line, and `DeployProjectSsh.fn.sh:335` emits `bash ./exec`, which overrides it. So both shebangs are inert, and the aggregate's own is the one a careful reader would otherwise trust.
- The real interpreter for those bodies is bash. `reference/shell.md` in `magic-developer` states which standard follows from that.
- The discriminator is the mechanism, not a count: a file installed as a real executable under `data/**` runs under its own shebang; a body hooked in through `image-install:exec-update-*:host/install/*.txt` does not. Read how a file is executed before deciding which standard it is held to.
- Open, not yet fixed: `DeployProjectSsh.fn.sh:335` emits `bash ./exec` unconditionally while the generated file declares `#!/bin/sh`, so a target carrying no bash fails at the last step.
