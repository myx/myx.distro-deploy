#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

"$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" \
	--debug \
	--import-from-source \
	--build-distro-from-sources \
	"$@" \
	--print ""
