#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi




# will need to re-run after that.

"$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" \
	--debug \
	--clean-output "$MMDAPP/output" \
	--print ""


# need to re-run, classes could have been loaded from output.

. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/DistroSourceCommand.fn.sh"

DistroSourceCommand \
	--source-root "$MMDAPP/source" \
	--output-root "$MMDAPP/output" \
	--debug \
	--import-from-source \
	--build-distro-from-sources \
	"$@" \
	--print ''
