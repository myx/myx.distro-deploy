#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )


# will need to re-run after that.

"$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/distro-source.sh" \
	--debug \
	--clean-output "$MMDAPP/output" \
	--print ""


# need to re-run, classes could have been loaded from output.

. "$MDLT_ORIGIN/myx/myx.distro-system/sh-scripts/DistroSourceCommand.fn.sh"

DistroSourceCommand \
	--source-root "$MMDAPP/source" \
	--output-root "$MMDAPP/output" \
	--debug \
	--import-from-source \
	--build-distro-from-sources \
	"$@" \
	--print ''
