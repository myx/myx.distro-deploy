#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

#
# Runs DistroCommand by compiling it's source code to a temporary folder 
#
DistroImageCommand(){
	local OUTPUT_PATH="${MDSC_OUTPUT:-$MMDAPP/output}"
	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"
	local MDSC_CACHED="${MDSC_CACHED:-$MMDAPP/output/cached}"

	local DIR_OUT="${MDSC_CACHED:-$MMDAPP/output/cached}/myx/myx.distro-source"
	local DIR_SRC="${MDSC_SOURCE:-$MMDAPP/source}/myx/myx.distro-source"

	local FIL_OUT="$DIR_OUT/bin/ru/myx/distro/DistroImageCommand.class"
	local FIL_CPL="$DIR_SRC/java/ru/myx/distro/DistroImageCommand.class"
	local FIL_SRC="$DIR_SRC/java/ru/myx/distro/DistroImageCommand.java"
	
	local HAS_OUT=$(test -f "$FIL_OUT" && echo 'true' || true)
	local HAS_CPL=$(test -f "$FIL_CPL" && echo 'true' || true)
	local HAS_SRC=$(test -f "$FIL_SRC" && echo 'true' || true)

	local USE_OUT=$(test -n "$HAS_OUT" && \
			test -z "$HAS_CPL" -o ! "$FIL_OUT" -ot "$FIL_CPL" && \
			test -z "$HAS_SRC" -o ! "$FIL_OUT" -ot "$FIL_SRC" && \
			echo "true" || true
		)

	local USE_CPL=$(test -n "$HAS_CPL" -a -z "$USE_OUT" && \
			test -z "$HAS_OUT" -o ! "$FIL_CPL" -ot "$FIL_OUT" && \
			test -z "$HAS_SRC" -o ! "$FIL_CPL" -ot "$FIL_SRC" && \
			echo "true" || true
		)

	local USE_SRC=$(test -n "$HAS_SRC" -a -z "$USE_OUT" -a -z "USE_CPL" && \
			test -z "$HAS_OUT" -o ! "$FIL_SRC" -ot "$FIL_OUT" && \
			test -z "$HAS_CPL" -o ! "$FIL_SRC" -ot "$FIL_CPL" && \
			echo "true" || true
		)

	test -n "$USE_SRC" -o -n "$USE_CPL" -o -n "$USE_OUT" || \
		( echo "No sources available, need to fetch!" ; false )

	test -z "$USE_OUT" || \
		java -cp "$DIR_OUT/bin" ru.myx.distro.DistroImageCommand \
			--output-root "$OUTPUT_PATH" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
	
	test -z "$USE_CPL" || \
		java -cp "$DIR_SRC/bin" ru.myx.distro.DistroImageCommand \
			--output-root "$OUTPUT_PATH" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"

	test -z "$USE_SRC" || (
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/RunJavaClassClean.include" ;
		RunJavaClassClean \
			"myx/myx.distro-source" \
			ru.myx.distro.DistroImageCommand \
			--output-root "$OUTPUT_PATH" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@" \
	)

	return 0
	
	test -z "$TMP_SRC" || (
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/RunJavaClassTemp.include" ;
		RunJavaClassTemp \
			"$MMDAPP/source/myx/myx.distro-source/java" \
			ru.myx.distro.DistroImageCommand \
			--output-root "$OUTPUT_PATH" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@" \
	)
}


case "$0" in
	*/sh-scripts/DistroImageCommand.fn.sh) 
		DistroImageCommand \
			"$@" \
			--print ''
	;;
esac