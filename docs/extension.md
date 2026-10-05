# Extension

[Back to the README](../README.md)

## Add a script to a project's install

Put install scripts in the project, then name them in `Declares`. [Formats](formats.md) lists every directive.

- `image-install:exec-update-before:host/install/<scriptName>` runs a script before the install.
- `image-install:exec-update-after:host/install/<scriptName>` runs a script after the install.
- The patch-script directives change prepared content at each step.

The installer reads a script named by `exec-update-*` into itself and runs it with bash. A shebang line inside that script is data, not an interpreter line, and has no effect.

A file installed as a real executable under `data/**` is different. It runs under its own shebang.

## Add files to the host

- `image-install:deploy-sync-files:<deploySourcePath>:<targetHostPath>` copies prepared files onto the host.
- `image-install:clone-deploy-file:...` clones one prepared file into many.

## Set a variable on the host

`image-install:context-variable:<name>:<operation>[:<value>...]` sets a variable. Use `import` or `source` to take the value from a file in a project.
