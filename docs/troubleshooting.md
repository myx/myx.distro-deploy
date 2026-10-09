# Troubleshooting

[Back to the README](../README.md)

## A selector matches nothing

A workspace may declare no deploy targets. A command that resolves nothing has found nothing to act on. That does not show broken tooling.

Run `ListSshTargets.fn.sh --all-targets` first. Check whether the workspace declares any targets before you look at the tool.

`ShellTo.fn.sh` exits 1 when a selector matches nothing.

## ShellTo refuses a selector

`ShellTo.fn.sh` needs exactly one target. When a selector matches several, it prints the matches, exits 2, and connects to none of them.

Narrow the selector. Check what it resolves to with `ListSshTargets.fn.sh`.

## Where a remote command is parsed

`--execute-command` quotes its value, so the remote shell parses it. A `|`, `;` or redirection in it runs on the target.

For a body with more than one line, use `--execute-stdin` or `--execute-script <path>`. They send the body over the wire as stdin.

## Options show up on the remote command line

Put every `--ssh-*`, `--no-sleep`, `--non-interactive` and `--execute-post-process` option before `--execute-command`, `--execute-script`, `--execute-stdin` or `--display-targets`.

The option parser stops at the first token it does not recognise. Anything after that token goes onto the remote command line.

## ssh: illegal option from ShellTo

`ShellTo` reads `--execute-stdin`, `--execute-script` and `--execute-command` only directly after the selector. `--display-targets` belongs to `ExecuteParallel` and `ExecuteSequence`. `ShellTo` does not take it.

Anywhere else, these words are folded into the remote command and surface as an ssh error. To pass a multi-word remote command, put it after a literal `--`:

	ShellTo.fn.sh <selector> --ssh-user root -- ae3 status

## ScreenTo says it must be connected to a terminal

`ScreenTo.fn.sh` needs a real terminal. A caller with no terminal gets this message after the project and connection resolve. For one command without a terminal, use `ShellTo.fn.sh`.

## ShellTo with no command aborts on the remote side

A bare `ShellTo.fn.sh <selector>` requests no remote terminal. The remote side stops on its own terminal check. This is a known fault and is not fixed.

For an interactive session, request the terminal through the trailing ssh arguments. `ScreenTo.fn.sh` does not have this fault.

## A deploy printed an ssh error and returned 0

`DeployProjectSsh.fn.sh` can print an SSH failure and still return 0. The exit status is not a deploy result.

Check the artefact. `DeployProjectSsh.fn.sh --project <project> --print-installer` should print the content you expect.

## The deploy fails at the last step on a host without bash

The generated installer is run with `bash ./exec`, whatever interpreter its own first line names. A target without bash fails at that step. This is a known fault and is not fixed.

## An edited tool still behaves as before

`Deploy <Tool> ...` loads `<Tool>.fn.sh` only when the function is not yet defined in the session. After an edit, call `<Tool>.fn.sh` directly. That redefines the function.

## A second workspace's console reports the first workspace

A `Distro*Console.sh` uses an `MMDAPP` that is already set. It works out its own workspace only when `MMDAPP` is unset or names no directory.

Run from a shell that already points at another workspace, the second console reads the first one's source tree. You see `no source folder!` or `No matching projects found` for projects that exist.

Clear the inherited variables first:

	cd <other-workspace> && env -u MMDAPP -u MDSC_CACHED -u MDSC_SOURCE -u MDSC_OUTPUT -u MDSC_OPTION -u MDSC_INMODE sh -c './DistroDeployConsole.sh --non-interactive'

## A guard abort left a directory on the host

The installer runs its terminal check before it creates any directory, so a stop at that check leaves the host untouched. The unpack directory is created before the clean-up is armed. A failure in that short window leaves the directory behind.
