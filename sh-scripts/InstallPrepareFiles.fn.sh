#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProvides
Require ListProjectSequence
Require ListProjectProvides
Require ListDistroProjects

InstallPrepareFiles(){
	set -e
	
	local projectName="$1" ; shift
	if [ -z "$projectName" ] ; then
		echo "InstallPrepareFiles: 'projectName' argument is required!" >&2 ; return 1
	fi

	case "$1" in
		--print-folders)
			local allProvides="`ListDistroProvides --all-provides-merged`"
		
			echo "$allProvides" | grep "^$projectName " | cut -d" " -f2,3 \
			| grep " image-prepare:sync-source-files:" | tr ':' ' ' | cut -d" " -f1,4- \
			| while read -r declaredAt sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: input: $declaredAt $sourceName $sourcePath $mergePath" >&2
				case "$sourceName" in
					'*')
						ListProjectSequence "$projectName" \
						| while read -r checkProject ; do
							local checkDirectory="$MDSC_SOURCE/$checkProject/$sourcePath"
							if [ -d "$checkDirectory" ] ; then
								if ListProjectSequence "$checkProject" | grep -q "$declaredAt" ; then
									echo "$checkProject" "$sourcePath" "$mergePath"
								fi
							fi
						done
					;;
					*)
						if [ "$sourceName" = "." ] ; then
							local sourceName="$declaredAt"
						fi
						if [ -d "$MDSC_SOURCE/$sourceName" ] ; then
							echo "$sourceName" "$sourcePath" "$mergePath"
						else
							echo "$allProvides" | grep " $sourceName$" | cut -d" " -f2 | awk '!x[$0]++' \
							| while read -r checkProject ; do
								local checkDirectory="$MDSC_SOURCE/$checkProject/$sourcePath"
								if [ -d "$checkDirectory" ] ; then
									echo "$checkProject" "$sourcePath" "$mergePath"
								fi
							done
						fi
					;;
				esac
			done \
			| awk '!x[$0]++' \
			| while read  -r sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $sourceName $sourcePath $mergePath" >&2
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi
				echo "$sourceName" "$sourcePath" "$mergePath"
			done 
			return 1
		;;
		--print-folders2)
			ListProjectProvides "$projectName" --merge-sequence --filter-and-cut image-prepare:sync-source-files | tr ':' ' ' \
			| while read -r declaredAt sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: input: $declaredAt $sourceName $sourcePath $mergePath" >&2
				case "$sourceName" in
					'*')
						ListProjectSequence "$projectName" \
						| while read -r checkProject ; do
							local checkDirectory="$MDSC_SOURCE/$checkProject/$sourcePath"
							if [ -d "$checkDirectory" ] ; then
								if ListProjectSequence "$checkProject" | grep -q "$declaredAt" ; then
									echo "$checkProject" "$sourcePath" "$mergePath"
								fi
							fi
						done
					;;
					*)
						if [ "$sourceName" = "." ] ; then
							local sourceName="$declaredAt"
						fi
						if [ -d "$MDSC_SOURCE/$sourceName" ] ; then
							echo "$sourceName" "$sourcePath" "$mergePath"
						else
							ListDistroProjects --select-provides "$sourceName" \
							| while read -r checkProject ; do
								local checkDirectory="$MDSC_SOURCE/$checkProject/$sourcePath"
								if [ -d "$checkDirectory" ] ; then
									echo "$checkProject" "$sourcePath" "$mergePath"
								fi
							done
						fi
					;;
				esac
			done \
			| awk '!x[$0]++' \
			| while read  -r sourceName sourcePath mergePath ; do
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi
				echo "$sourceName" "$sourcePath" "$mergePath"
			done 
			return 1
		;;
		--print-files)
			InstallPrepareFiles "$projectName" --print-folders \
			| while read  -r sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $sourceName $sourcePath $mergePath" >&2
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi
				find "$fileName" -type f | sed -e "s:^$fileName/:$fileName :" -e "s:\$: $mergePath:"
			done \
			| tail -r | awk '!x[$2]++' | sort -k3,2
			return 0
		;;
		--print-files2)
			InstallPrepareFiles "$projectName" --print-folders2 \
			| while read  -r sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $sourceName $sourcePath $mergePath" >&2
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi
				find "$fileName" -type f | sed -e "s:^$fileName/:$fileName :" -e "s:\$: $mergePath:"
			done \
			| tail -r | awk '!x[$2]++' | sort -k3,2
			return 0
		;;
		--to-directory)
			shift
		 	local targetPath="$1" ; shift
			if [ -z "$targetPath" ] ; then
				echo "ERROR: InstallPrepareFiles: 'targetDirectory' (or --no-write)  argument is required!" >&2
				return 1
			fi
			InstallPrepareFiles "$projectName" --print-folders \
			| while read  -r sourceName sourcePath mergePath ; do
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi
				mkdir -p "$targetPath/$mergePath"
				rsync -r --chmod=ug+rw --omit-dir-times "$fileName/" "$targetPath/$mergePath/"
			done
			return 0
		;;
		--to-directory2)
			shift
		 	local targetPath="$1" ; shift
			if [ -z "$targetPath" ] ; then
				echo "ERROR: InstallPrepareFiles: 'targetDirectory' (or --no-write)  argument is required!" >&2
				return 1
			fi
			InstallPrepareFiles "$projectName" --print-files \
			| while read  -r sourceBase sourcePath mergePath ; do
				rsync "$sourceBase/$sourcePath/" "$targetPath/$mergePath/$sourcePath/"
			done
			return 1
		;;
		--to-temp)
			local tempDirectory="`mktemp -d -t "MDSC_IPF"`"
			echo "InstallPrepareFiles: using temp: $tempDirectory" >&2
			InstallPrepareFiles "$projectName" --to-directory "$tempDirectory"
			echo "InstallPrepareFiles: temp prepared" >&2
			trap "rm -rf $tempDirectory" EXIT

			( cd "$tempDirectory" ; find "." -type f | sort ) 
		;;
		--to-temp2)
			local tempDirectory="`mktemp -d -t "MDSC_IPF"`"
			echo "InstallPrepareFiles: using temp: $tempDirectory" >&2
			InstallPrepareFiles "$projectName" --to-directory2 "$tempDirectory"
			echo "InstallPrepareFiles: temp prepared" >&2
			trap "rm -rf $tempDirectory" EXIT

			( cd "$tempDirectory" ; find "." -type f | sort ) 
		;;
	esac

}

case "$0" in
	*/sh-scripts/InstallPrepareFiles.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: InstallPrepareFiles.fn.sh <project> --print-folders/--print-files/--to-temp" >&2
			echo "syntax: InstallPrepareFiles.fn.sh <project> --to-directory <targetDirectory>" >&2
			echo "syntax: InstallPrepareFiles.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz --print-folders" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.knt/setup.host-ndns111r3.ndm9.xyz --print-files" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.knt/setup.host-ndns111r3.ndm9.xyz --to-temp" >&2
			fi
			exit 1
		fi
		
		InstallPrepareFiles "$@"
	;;
esac