#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProvides
Require ListProjectSequence
Require ListProjectProvides
Require ListDistroProjects

if ! type ImagePrepare >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.image-prepare.include"
fi

InstallPrepareFiles(){

	set -e

	[ -z "$MDSC_DETAIL" ] || echo "> InstallPrepareFiles $@" >&2
	# [ -z "$MDSC_DETAIL" ] || printf "| InstallPrepareFiles: \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2
	
	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	
	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "ERROR: InstallPrepareFiles: project is not selected!" >&2
		return 1
	fi

	case "$1" in
		--print-sync-folders)
			DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME

			local projectProvides="$( grep -e "^$MDSC_PRJ_NAME \\S* image-prepare:" < "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' )"
		
			echo "$projectProvides" \
			| grep " image-prepare:sync-source-files:" | tr ':' ' ' | cut -d" " -f1,4- \
			| while read -r declaredAt sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: input: $declaredAt $sourceName $sourcePath $mergePath" >&2
				DistroImageCheckSourcePath --path --project "$MDSC_PRJ_NAME" "$declaredAt" "$sourceName" "$sourcePath" "$mergePath" \
				| cut -d" " -f2-
			done \
			| awk '!x[$0]++' \
			| while read -r sourceName sourcePath mergePath ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: process: $declaredAt $sourceName $sourcePath $mergePath" >&2
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
			DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME
		
			local projectProvides="$( grep -e "^$MDSC_PRJ_NAME \\S* image-prepare:" < "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' )"
		
			echo "$projectProvides" \
			| grep " image-prepare:clone-source-file:" | tr ':' ' ' | cut -d" " -f1,4- \
			| while read -r declaredAt sourceName sourcePath fileName targetPattern useVariable useValues ; do
				[ -z "$MDSC_DETAIL" ] || echo "InstallPrepareFiles: input: $declaredAt $sourceName $sourcePath $fileName $targetPattern $useVariable $useValues" >&2
				DistroImageCheckSourcePath --file --project "$MDSC_PRJ_NAME" "$declaredAt" "$sourceName" "$sourcePath/$fileName" "$sourcePath" "$fileName" "$targetPattern" "$useVariable" "$useValues" \
				| cut -d" " -f2,4-
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
			local allSyncFolders="$( InstallPrepareFiles --print-sync-folders )"
			local allCloneFiles="$( InstallPrepareFiles --print-clone-files )"
			
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

			local allSyncFolders="$( InstallPrepareFiles --print-sync-folders )"
			local allCloneFiles="$( InstallPrepareFiles --print-clone-files )"
			
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
			InstallPrepareFiles --to-directory "$tempDirectory"
			echo "InstallPrepareFiles: temp prepared" >&2

			cd "$tempDirectory"
			
			if [ -z "$1" ] ; then
				find "." -type f | sort
				return 0 
			fi
			 
			eval "$@"
			return 0 
		;;
		--to-deploy-output)
			if [ ! -d "$MMDAPP/output" ] ; then
				echo "ERROR: InstallPrepareFiles: deploy-output directory is missing: $MMDAPP/output" >&2; 
				return 1
			fi
			InstallPrepareFiles --to-directory "$MMDAPP/output/deploy/$MDSC_PRJ_NAME"
			return 0
		;;
	esac

}

case "$0" in
	*/sh-scripts/InstallPrepareFiles.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --print-sync-folders/--print-clone-files" >&2
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --print-sync-files" >&2
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --to-temp <command> [<argument...>]" >&2
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --to-directory <targetDirectory>" >&2
			echo "syntax: InstallPrepareFiles.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-sync-folders" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-sync-files" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-clone-files" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp find . | sort | grep web/default" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp 'pwd ; find . | sort'" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp tar czvf - . > /dev/null" >&2
			fi
			exit 1
		fi
		
		InstallPrepareFiles "$@"
	;;
esac