#/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )

"$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" \
	--debug \
	--import-from-source \
	--build-distro-from-sources \
	"$@" \
	--print ""
