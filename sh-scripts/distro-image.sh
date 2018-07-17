#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroFromImage.include"

DistroFromImage "$@"

# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-project setup.host-meloscope.kimsufi.co.nz -vv --select-required --print-selected
# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-project setup.server-ndls.dev.ndm9.xyz -vv --select-required --print-selected

# ./distro/distro-image.sh --output-root ../output --import-from-cached --select-providers java --print-selected -p "" --select-required --print-selected -p "" --unselect-project os-myx.common-ubuntu --print-selected -p "" --select-required --print-selected -p "" --unselect-providers os.ubuntu --print-selected
# ./distro/distro-image.sh -vv --output-root ../output --import-from-cached --select-providers java --print-selected -p "" --select-required --print-selected -p "" --unselect-project os-myx.common-ubuntu --print-selected -p "" --select-required --print-selected -p "" --unselect-providers os.ubuntu --print-selected
# ./distro/distro-image.sh -vv --output-root ../output --import-from-cached --select-providers :build --print-selected
