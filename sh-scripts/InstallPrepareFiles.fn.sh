#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

if ! type ImagePrepare >/dev/null 2>&1 ; then
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.image-prepare.include"
fi

##
## Internal - prints script using prepared variables
##
InstallPrepareFilesInternalPrintScript(){

	set -e

	local MDSC_CMD="InstallPrepareFiles[--print-script]"
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	##
	## coarse-check parameters are legit
	##
	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not selected!" >&2
		set +e ; return 1
	fi

	##
	## early-select data required
	##
	[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: select property lists" >&2
	local allSyncFolders="$( ImagePrepareProjectSyncFolders )"
	local allSourceScripts="$( ImagePrepareProjectSourcePatchScripts )"
	local allCloneTasks="$( ImagePrepareProjectCloneTasks )"
	local allTargetScripts="$( ImagePrepareProjectTargetPatchScripts )"

	##
	## build prepare script start
	##
	cat "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/ImagePrepareFiles.prefix.include"

	##
	## check debug logging settings
	##
	if [ "full" = "$MDSC_DETAIL" ] ; then
		echo 'echo "ImagePrepareFiles: 🔬🦠 full-detail debugging is ON"'
		echo 'set -x'
	fi
	
	##
	## set variables
	##
	[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: discover context variables and values" >&2
	DistroImageProjectContextVariables --prepare --export

	##
	## sync files from source to output
	##
	local sourceName sourcePath mergePath filterGlob
	if [ -n "${allSyncFolders:0:1}" ] ; then
		[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: sync files from source to output" >&2
		echo '{'
			echo 'echo "ImagePrepareFiles: 🔁 syncing files..." >&2'
			echo "$allSyncFolders" | cut -d" " -f 3 | sort -u | xargs echo mkdir -p
			echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath filterGlob ; do
				# echo "mkdir -p './$mergePath'"
				if [ -z "$filterGlob" ] ; then
					echo "rsync -rtO --chmod=ug+rwX '$MDSC_SOURCE/$sourceName/$sourcePath/' './$mergePath/'"
				else
					echo "rsync -rtO --include='$filterGlob' --exclude='*' --chmod=ug+rwX '$MDSC_SOURCE/$sourceName/$sourcePath/' './$mergePath/'"
				fi
			done
		echo "} 2>&1 | (grep -v --line-buffered -E '^>f\\.\\.t\\.+ ' >&2 || true)"
	fi

	##
	## clone/multiply files
	##
	local sourceName sourcePath mergePath filterGlob
	if [ -n "${allSyncFolders:0:1}" ] ; then
		[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: clone/multiply files" >&2
		local executeScript="$(
			echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath filterGlob ; do
				local targetFullPath="./${mergePath##/}"
				local sourceName cloneSourcePath sourceFileName targetPattern useVariable useValues
				[ -z "${allCloneTasks:0:1}" ] || echo "$allCloneTasks" | grep "^$sourceName $sourcePath " \
				| while read  -r sourceName cloneSourcePath sourceFileName targetPattern useVariable useValues; do
					if [ -z "$useVariable" ] ; then
						echo "cp -f '$targetFullPath/${cloneSourcePath##$sourcePath}$sourceFileName' '$targetFullPath/$targetPattern'"
						continue
					fi

					useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
					
					local sourceText="" editorCode=""
					for useValue in $useValues ; do
						sourceText="$sourceText $targetFullPath/$targetPattern"
						editorCode="$editorCode -e 's:$useVariable:$useValue:'"
					done
					
					if [ -z "$sourceText" ] ; then
						echo "# 🙋 WARNING: no targets for cloning task: '${cloneSourcePath##$sourcePath}$sourceFileName'"
						continue
					fi

					useValues="$( echo "$sourceText" | eval sed $editorCode )"
					
					echo "cat '$targetFullPath/${cloneSourcePath##$sourcePath}$sourceFileName' | tee $useValues > /dev/null"
					continue					
				done 
			done
		)"
		if [ -n "${executeScript:0:1}" ] ; then
			echo '{'
				echo 'echo "ImagePrepareFiles: 🔂 clone/multiply files..." >&2'
				echo "$executeScript"
			echo "} 2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
		fi
	fi

	##
	## execute source path-related patches 
	##
	local sourceName sourcePath mergePath filterGlob
	[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: execute source path-related patches" >&2
	[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
	| while read -r sourceName sourcePath mergePath filterGlob ; do
		local matchSourceName sourcePath scriptSourceName scriptName
		[ -z "${allSourceScripts:0:1}" ] || echo "$allSourceScripts" | grep -e "^$sourceName " | cut -d" " -f2- \
		| while read -r matchSourcePath scriptSourceName scriptName ; do
			case "${matchSourcePath##/}/" in
				"${sourcePath##/}/"*)
					[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchSourcePath ?= $sourcePath" >&2
					echo "$scriptSourceName" "$scriptName" "${mergePath%/}/${matchSourcePath#${sourcePath%/}}"
					continue
				;;
			esac
		done
	done \
	| awk '!x[$0]++' \
	| while read -r scriptSourceName scriptName mergePath; do
		DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptName" "./$mergePath"
	done

	##
	## execute target path-related patches
	##
	[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: execute target path-related patches" >&2
	local sourceName sourcePath mergePath filterGlob
	local scriptSourceName scriptName matchTargetPath
	[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
	| while read -r sourceName sourcePath mergePath filterGlob ; do
		[ -z "${allTargetScripts:0:1}" ] || echo "$allTargetScripts" \
		| while read -r scriptSourceName scriptName matchTargetPath; do
			case "$matchTargetPath" in
				*'*')
					local globTargetPath="${matchTargetPath%'*'}"
					case "${mergePath%/}" in
						"${globTargetPath%/}/"*)
							[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchTargetPath ?= $mergePath" >&2
							echo "$scriptSourceName" "$scriptName" "${mergePath%/}"
							continue
						;;
					esac
				;;
				'*'*)
					echo "$MDSC_CMD: suffix search is not supported!" >&2
					set +e ; return 1
				;;
				*)
					case "${matchTargetPath%/}/" in
						"${mergePath%/}/"*)
							[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchTargetPath ?= $mergePath" >&2
							echo "$scriptSourceName" "$scriptName" "${mergePath%/}${matchTargetPath#${mergePath%/}}"
							continue
						;;
					esac
				;;
			esac
		done
	done \
	| awk '!x[$0]++' \
	| while read -r scriptSourceName scriptName mergePath; do
		DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptName" "./$mergePath"
	done
	
	##
	## build prepare script end
	##
	cat "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/ImagePrepareFiles.suffix.include"
	
	echo 'exit 0'
	return 0
}

InstallPrepareFiles(){

	set -e

	local MDSC_CMD='InstallPrepareFiles'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	[ "full" != "$MDSC_DETAIL" ] || printf "| $MDSC_CMD: 🔬🦠 \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2
	
	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	local saveScriptTo=""
	local directoryNew=""
	
	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			--save-script)
				shift ; saveScriptTo="$1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not selected!" >&2
		set +e ; return 1
	fi

	case "$1" in
		--print-sync-folders)
			ImagePrepareProjectSyncFolders
			return 0
		;;
		--print-clone-tasks)
			ImagePrepareProjectCloneTasks \
		;;
		--print-clone-files)
			local sourceName sourcePath fileName targetPattern useVariable useValues
			ImagePrepareProjectCloneTasks \
			| while read  -r sourceName sourcePath fileName targetPattern useVariable useValues; do
				if [ -z "$useVariable" ] ; then
					echo "$sourceName" "$sourcePath" "$fileName" "$targetPattern"
				else
					useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
					for useValue in $useValues ; do
						echo "$sourceName" "$sourcePath" "$fileName" "$( echo "$targetPattern" | sed "s:$useVariable:$useValue:" )"
					done
				fi
			done 
			return 0
		;;
		--print-source-patch-scripts)
			ImagePrepareProjectSourcePatchScripts
			return 0
		;;
		--print-target-patch-scripts)
			ImagePrepareProjectTargetPatchScripts
			return 0
		;;
		--print-context-variables)
			shift
			DistroImageProjectContextVariables --prepare "$@"
			return 0
		;;
		--print-script)
			InstallPrepareFilesInternalPrintScript
			return 0 
		;;
		--to-directory)
			shift
		 	local targetPath="$1" ; shift
			if [ -z "$targetPath" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: 'targetDirectory' argument is required!" >&2
				set +e ; return 1
			fi

			mkdir -p "$targetPath"
			
			if [ -z "$saveScriptTo" ] ; then
				if ! local executeScript="$( InstallPrepareFilesInternalPrintScript )" ; then
					echo "$MDSC_CMD: ⛔ ERROR: building image-prepare script!" >&2
				fi
			else
				if ! local executeScript="$( InstallPrepareFilesInternalPrintScript | tee "$saveScriptTo" )" ; then
					echo "$MDSC_CMD: ⛔ ERROR: building image-prepare script!" >&2
				fi
			fi
			
			if [ -z "$directoryNew" ] ; then
				local tempDirectory="`mktemp -d -t "MDSC_IPF_XXXXXXXX"`"
				local saveDirectory="`pwd`"
				trap "cd '$saveDirectory' ; rm -rf '$tempDirectory'" EXIT
				echo "$MDSC_CMD: using temp: $tempDirectory" >&2
				if ! ( set -e ; cd "$tempDirectory" ; eval "$executeScript" ) ; then
					echo "$MDSC_CMD: ⛔ ERROR: executing image-prepare script!" >&2
				fi
				rsync -iprltOoD --delete --chmod=ug+rwX "$tempDirectory/" "$targetPath" 2>&1 \
					| (grep -v --line-buffered -E '^>f\\.\\.t\\.+ ' >&2 || true)
			else
				if ! ( set -e ; cd "$targetPath" ; eval "$executeScript" ) ; then
					echo "$MDSC_CMD: ⛔ ERROR: executing image-prepare script!" >&2
				fi
			fi

			
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: done." >&2
			return 0
		;;
		--to-temp)
			shift
			local tempDirectory="`mktemp -d -t "MDSC_IPF_XXXXXXXX"`"
			local saveDirectory="`pwd`"
			local directoryNew="true"
			trap "cd '$saveDirectory' ; rm -rf '$tempDirectory'" EXIT
			echo "$MDSC_CMD: using temp: $tempDirectory" >&2
			InstallPrepareFiles --to-directory "$tempDirectory"
			echo "$MDSC_CMD: temp prepared" >&2

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
				echo "$MDSC_CMD: ⛔ ERROR: deploy-output directory is missing: $MMDAPP/output" >&2; 
				set +e ; return 1
			fi
			InstallPrepareFiles --to-directory "$MMDAPP/output/deploy/$MDSC_PRJ_NAME"
			return 0
		;;
		--to-deploy-output-clean)
			if [ ! -d "$MMDAPP/output" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: deploy-output directory is missing: $MMDAPP/output" >&2; 
				set +e ; return 1
			fi
			InstallPrepareFiles --to-temp "rsync -iprltOoD --delete --chmod=ug+rwX ./ '$MMDAPP/output/deploy/$MDSC_PRJ_NAME' 2>&1 | (grep -v --line-buffered -E '^>f\\.\\.t\\.+ ' >&2 || true)"
			return 0
		;;
	esac

}

case "$0" in
	*/sh-scripts/InstallPrepareFiles.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: InstallPrepareFiles.fn.sh --project <project> --print-sync-folders/--print-clone-files/--print-script" >&2
			echo "📘 syntax: InstallPrepareFiles.fn.sh --project <project> --to-temp <command> [<argument...>]" >&2
			echo "📘 syntax: InstallPrepareFiles.fn.sh --project <project> [--save-script <fileName>] --to-directory <targetDirectory>" >&2
			echo "📘 syntax: InstallPrepareFiles.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-sync-folders" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-clone-files" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-source-patch-scripts" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-target-patch-scripts" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp find . | sort | grep web/default" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp 'pwd ; find . | sort'" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp tar czvf - . > /dev/null" >&2
			fi
			exit 1
		fi
		
		InstallPrepareFiles "$@"
	;;
esac
