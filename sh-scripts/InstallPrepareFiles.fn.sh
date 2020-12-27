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
		--print-sync-folders)
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
			return 0
		;;
		--print-clone-files)
			local allProvides="`ListDistroProvides --all-provides-merged`"
		
			echo "$allProvides" | grep "^$projectName " | cut -d" " -f2,3 \
			| grep " image-prepare:clone-source-file:" | tr ':' ' ' | cut -d" " -f1,4- \
			| while read -r declaredAt sourceName sourcePath fileName targetPattern useVariable useValues ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: input: $declaredAt $sourceName $sourcePath $fileName $targetPattern $useVariable $useValues" >&2
				case "$sourceName" in
					'*')
						ListProjectSequence "$projectName" \
						| while read -r checkProject ; do
							local checkPath="$MDSC_SOURCE/$checkProject/$sourcePath/$fileName"
							if [ -f "$checkPath" ] ; then
								if ListProjectSequence "$checkProject" | grep -q "$declaredAt" ; then
									echo "$checkProject" "$sourcePath" "$fileName" "$targetPattern" "$useVariable" "$useValues"
								fi
							fi
						done
					;;
					*)
						if [ "$sourceName" = "." ] ; then
							local sourceName="$declaredAt"
						fi
						if [ -f "$MDSC_SOURCE/$sourceName/$fileName" ] ; then
							echo "$sourceName" "$sourcePath" "$fileName" "$targetPattern" "$useVariable" "$useValues"
						else
							echo "$allProvides" | grep " $sourceName$" | cut -d" " -f2 | awk '!x[$0]++' \
							| while read -r checkProject ; do
								local checkPath="$MDSC_SOURCE/$checkProject/$sourcePath/$fileName"
								if [ -f "$checkPath" ] ; then
									echo "$checkProject" "$sourcePath" "$fileName" "$targetPattern" "$useVariable" "$useValues"
								fi
							done
						fi
					;;
				esac
			done \
			| awk '!x[$0]++' \
			| while read  -r sourceName sourcePath fileName targetPattern useVariable useValues; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $sourceName $sourcePath $targetPattern $useVariable $useValues" >&2
				if [ -z "$useVariable" ] ; then
					echo "$sourceName" "$sourcePath" "$fileName" "$targetPattern"
				else
					local useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
					for useValue in $useValues ; do
						echo "$sourceName" "$sourcePath" "$fileName" "` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `"
					done
				fi
			done 
			return 0
		;;
		--print-sync-files)
			local allSyncFolders="` InstallPrepareFiles "$projectName" --print-sync-folders `"
			local allCloneFiles="` InstallPrepareFiles "$projectName" --print-clone-files `"
			
			echo "$allSyncFolders" \
			| while read  -r sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $sourceName $sourcePath $mergePath" >&2
				local fileName="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$fileName" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $fileName" >&2; 
					return 1
				fi

				find "$fileName" -type f | sed -e "s:^$fileName/:$fileName :" \
				| while read -r sourceFullPath sourceFileName ; do
					echo "$sourceFullPath/$sourceFileName" "$mergePath/$sourceFileName"
				done 

				echo "$allCloneFiles" | grep "^$sourceName $sourcePath " \
				| while read sourceName sourcePath sourceFileName targetFileName extraCrap ; do
					echo "$MDSC_SOURCE/$sourceName/$sourcePath/$sourceFileName" "$mergePath/$targetFileName"
				done

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

			local allSyncFolders="` InstallPrepareFiles "$projectName" --print-sync-folders `"
			local allCloneFiles="` InstallPrepareFiles "$projectName" --print-clone-files `"
			
			echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				local sourceFullPath="$MDSC_SOURCE/$sourceName/$sourcePath"
				if [ ! -d "$sourceFullPath" ] ; then
					echo "ERROR: InstallPrepareFiles: directory is missing: $sourceFullPath" >&2 
					return 1
				fi
				
				local targetFullPath="$targetPath/$mergePath"
				mkdir -p "$targetFullPath"
				rsync -rt --chmod=ug+rw --omit-dir-times "$sourceFullPath/" "$targetFullPath/"
			
				echo "$allCloneFiles" | grep "^$sourceName $sourcePath " \
				| while read -r sourceName sourcePath sourceFileName targetFileName ; do
					rsync -rt --chmod=ug+rw "$sourceFullPath/$sourceFileName" "$targetFullPath/$targetFileName"
				done
			done
			return 0
		;;
		--to-temp)
			shift
			local tempDirectory="`mktemp -d -t "MDSC_IPF"`"
			local saveDirectory="`pwd`"
			trap "cd '$saveDirectory' ; rm -rf '$tempDirectory'" EXIT
			echo "InstallPrepareFiles: using temp: $tempDirectory" >&2
			InstallPrepareFiles "$projectName" --to-directory "$tempDirectory"
			echo "InstallPrepareFiles: temp prepared" >&2

			cd "$tempDirectory"
			
			if [ -z "$1" ] ; then
				find "." -type f | sort
				return 0 
			fi
			 
			"$@"
			return 0 
		;;
		--to-deploy-output)
			if [ ! -d "$MMDAPP/output" ] ; then
				echo "ERROR: InstallPrepareFiles: deploy-output directory is missing: $MMDAPP/output" >&2; 
				return 1
			fi
			InstallPrepareFiles "$projectName" --to-directory "$MMDAPP/output/deploy/$projectName"
			return 0
		;;
	esac

}

case "$0" in
	*/sh-scripts/InstallPrepareFiles.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: InstallPrepareFiles.fn.sh <project> --print-sync-folders/--print-clone-files" >&2
			echo "syntax: InstallPrepareFiles.fn.sh <project> --print-sync-files" >&2
			echo "syntax: InstallPrepareFiles.fn.sh <project> --to-temp <command> [<argument...>]" >&2
			echo "syntax: InstallPrepareFiles.fn.sh <project> --to-directory <targetDirectory>" >&2
			echo "syntax: InstallPrepareFiles.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --print-sync-folders" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --print-clone-files" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --print-sync-files" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --to-temp find . | sort | grep web/default" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --to-temp 'pwd ; find . | sort'" >&2
				echo "    InstallPrepareFiles.fn.sh ndm/cloud.ndm/setup.host-ndns011.ndm9.net --to-temp tar czvf - . > /dev/null" >&2
			fi
			exit 1
		fi
		
		InstallPrepareFiles "$@"
	;;
esac