#!/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ "--eval" = "$1" ] ; then
	set -e
	type DistroImage >/dev/null 2>&1 || \
		. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"
	shift
	eval "$@"
	exit 0
fi

. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/DistroFromImage.include"

DistroFromImage "$@"

# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-project myx/setup.host-meloscope.kimsufi.co.nz -vv --select-required --print-selected
# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-project ndm/setup.server-ndls.dev.example.org -vv --select-required --print-selected

# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-providers java --print-selected -p "" --select-required --print-selected -p "" --unselect-project os-myx.common-ubuntu --print-selected -p "" --select-required --print-selected -p "" --unselect-providers os.ubuntu --print-selected
# ./distro/distro-image.sh -vv --output-root ../output --import-from-cached --select-providers java --print-selected -p "" --select-required --print-selected -p "" --unselect-project os-myx.common-ubuntu --print-selected -p "" --select-required --print-selected -p "" --unselect-providers os.ubuntu --print-selected
# ./distro/distro-image.sh -vv --output-root ../output --import-from-cached --select-providers :build --print-selected
