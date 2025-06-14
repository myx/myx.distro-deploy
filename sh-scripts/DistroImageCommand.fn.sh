#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

#
# Runs DistroCommand by compiling it's source code to a temporary folder 
#
DistroImageCommand(){
	local MDSC_OUTPUT="${MDSC_OUTPUT:-$MMDAPP/output}"
	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"
	local MDSC_CACHED="${MDSC_CACHED:-$MMDAPP/output/cached}"

	local DIR_OUT="$MDSC_CACHED/myx/myx.distro-source"
	local DIR_SRC="$MDSC_SOURCE/myx/myx.distro-source"

	set -e

	if [ -f "$DIR_OUT/bin/ru/myx/distro/DistroImageCommand.class" ] ; then
		java -cp "$DIR_OUT/bin" ru.myx.distro.DistroImageCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi
	
	if [ -f "$DIR_SRC/java/ru/myx/distro/DistroImageCommand.class" ] ; then
		java -cp "$DIR_OUT/bin" ru.myx.distro.DistroImageCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi
	
	if [ -f "$DIR_SRC/java/ru/myx/distro/DistroImageCommand.java" ] ; then
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/RunJavaClassClean.include" ;
		RunJavaClassClean \
			"myx/myx.distro-source" \
			ru.myx.distro.DistroImageCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi

	echo "DistroImageCommand: No sources available, need to fetch!" >&2
	set +e ; return 1
}


case "$0" in
	*/sh-scripts/DistroImageCommand.fn.sh) 
		DistroImageCommand "$@" --print ''
	;;
esac
