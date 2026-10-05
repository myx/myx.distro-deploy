# Troubleshooting

[Back to the README](../README.md)

Scope: symptoms, causes and actions.

## A command is refused because a selector matches several targets

`ShellTo.fn.sh` refuses a selector that matches more than one target, and does not connect. Check the selector with `ListSshTargets.fn.sh`, then narrow it. See [Use](use.md).

## Options appear on the remote command line

Put every `--ssh-*`, `--no-sleep`, `--non-interactive` and `--execute-post-process` option before the execute option. See [Use](use.md).

Traps the team has recorded are in [MAGIC.md](../MAGIC.md).
