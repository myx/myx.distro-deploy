#!/usr/bin/env bash

##
## NOTE:
## Designed to be able to run without distro context. Used to install required parts.
##

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/.local" ] || ( echo "⛔ ERROR: expecting '.local' directory." >&2 && exit 1 )
fi

DistroDeployTools(){
	local MDSC_CMD='DistroDeployTools'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	case "$1" in
		--make-*)
			. "$MMDAPP/.local/myx/myx.distro-deploy/sh-lib/DeployTools.Make.include"
			set +e ; return 1
		;;
		--*-config-option)
			. "$MMDAPP/.local/myx/myx.distro-.local/sh-lib/LocalTools.Config.include"
			set +e ; return 1
		;;
		--upgrade-deploy-tools)
			shift
			bash "$MMDAPP/.local/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh" --install-distro-deploy
			return 0
		;;
		''|--help)
			echo "📘 syntax: DistroDeployTools.fn.sh <option>" >&2
			echo "📘 syntax: DistroDeployTools.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				cat "$MMDAPP/.local/myx/myx.distro-deploy/sh-lib/HelpDistroDeployTools.text" >&2
			fi
			set +e ; return 1
		;;
		*)
			echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
			set +e ; return 1
		;;
	esac
}

case "$0" in
	*/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: DistroDeployTools.fn.sh --upgrade-deploy-tools" >&2
		fi

		set -e
		DistroDeployTools "$@"
	;;
esac
