#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type ImageInstall >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.image-install.include"
fi


##
## Internal - prints script using prepared variables
##
DeployProjectSshInternalPrintRemoteScript(){

	set -e

	local MDSC_CMD="DeployProjectSsh[--print-$deployType-script]"
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	##
	## coarse-check parameters are legit
	##
	if [ "${cacheFolder#"$MMDAPP/output"}" = "$cacheFolder" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: invalid context: cacheFolder: $cacheFolder" >&2
		set +e ; return 1
	fi

	##
	## check if scripts (exec) are needed
	##
	if [ "$deployType" != "sync" ] ; then
		if [ "true" = "$prepareScript" ] || [ "auto" = "$prepareScript" -a  ! -f "$cacheFolder/exec"  ] ; then
			Require InstallPrepareScript
			InstallPrepareScript --project "$MDSC_PRJ_NAME" $MATCH_SCRIPT_FILTER --to-file "$cacheFolder/exec"
		fi
		if [ ! -f "$cacheFolder/exec" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: no installer script found ($cacheFolder/exec)" >&2
			set +e ; return 1
		fi
	fi

	##
	## check if files (sync) are needed
	##
	if [ "$deployType" != "exec" ] ; then
		if [ "true" = "$prepareFiles" ] || [ "auto" = "$prepareFiles" -a  ! -d "$cacheFolder/sync"  ] ; then
			Require InstallPrepareFiles
			InstallPrepareFiles --project "$MDSC_PRJ_NAME" --to-directory "$cacheFolder/sync"
		fi
		if [ ! -d "$cacheFolder/sync" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: no installer files found ($cacheFolder/sync)" >&2
			set +e ; return 1
		fi
	fi

	# local projectProvides="$( grep -e "^$MDSC_PRJ_NAME \\S* image-install:" < "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' )"
	local projectProvides="$( ImageInstallProjectProvidesMerged )"
	
	if [ "$deployType" != "exec" ] ; then
		##
		## select sync tasks
		##
		local deploySyncFilesTasks="$( ImageInstallProjectSyncTasks )"
		local deploySourcePatchScripts="$( ImageInstallProjectDeployPatchScripts --source )"
		local deployTargetPatchScripts="$( ImageInstallProjectDeployPatchScripts --target )"
	fi

	echo '#!/bin/sh'

	##
	## sleep, if needed
	##
	if [ "true" = "$executeSleep" ] ; then
		echo "ImageDeploy: ⏳ ... sleeping for 5 seconds ..." >&2
		sleep 5
	fi

	[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: building remote script" >&2

	##
	## set detailed logging on remote host
	##
	[ -z "$MDSC_DETAIL" ] || echo 'export MDSC_DETAIL=true'

	echo "export MDSC_PRJ_NAME='$MDSC_PRJ_NAME'"
	echo "export MDSC_REAL_USER='${MDSC_REAL_USER:-${SUDO_USER:-$USER}}'"

	##
	## check debug logging settings
	##
	if [ "full" = "$MDSC_DETAIL" ] ; then
		echo 'echo "ImageDeploy: 🔬🦠 full-detail debugging is ON"'
		echo 'set -x'
	fi
	
	##
	## set variables
	##
	DistroImageProjectContextVariables --install --export

	##
	## remote host script start
	##
	cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.prefix.include"

	##
	## FIXME: should it be here?
	## insert useful shell functions
	##
	# myx.common cat lib/notifySmart

	echo 'echo "ImageDeploy: 📦 uploading sync files..." >&2'

	##
	## embed files needed
	##
	[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: pack deploy files from $cacheFolder/" >&2
	
	# replaced by linux hack: printf "\n( uudecode -p | tar jxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
	printf "\n( uudecode -o /dev/stdout | tar jxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
	tar jcf - -C "$cacheFolder/" $( echo "$deployType" | sed 's|full|sync exec|' ) | uuencode -m packed.tbz
	printf '\nEOF_PROJECT_TAR_XXXXXXXX\n\n'
	
	##
	## check do sync
	##
	if [ "$deployType" != "exec" ] ; then
		[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: building sync script" >&2
		echo 'echo "ImageDeploy: 🔁 syncing files..." >&2'

		##
		## execute global patches before processing files
		##
		local scriptSourceName scriptFile sourcePath
		ImageInstallProjectDeployPatchScripts --prefix \
		| while read -r scriptSourceName scriptFile sourcePath; do
			DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$sourcePath"
		done

		##
		## for every sync task
		##
		local sourcePath targetPath
		if [ -n "${deploySyncFilesTasks:0:1}" ] ; then
			echo "$deploySyncFilesTasks" \
			| while read -r sourcePath targetPath; do
	
				##
				## execute path-related patches before processing files
				##
				local scriptSourceName scriptFile matchSourcePath
				[ -z "${deploySourcePatchScripts:0:1}" ] || echo "$deploySourcePatchScripts" \
				| while read -r scriptSourceName scriptFile matchSourcePath; do
					case "${matchSourcePath##/}/" in
						"${sourcePath##/}/"*)
							DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$matchSourcePath"
						;;
						*)
							[ "full" != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path skipped: $matchSourcePath ?= $sourcePath" >&2
						;;
					esac
				done
	
				##
				## clone/multiply files
				##
				local declaredAt sourcePath filePath fileName targetPattern useVariable useValues localFileName
				echo "$projectProvides" \
				| grep " image-install:clone-deploy-file:$sourcePath:" \
				| tr ':' ' ' | cut -d" " -f1,4- \
				| while read -r declaredAt sourcePath filePath fileName targetPattern useVariable useValues; do
					localFileName="$cacheFolder/sync/$sourcePath/$filePath/$fileName"
					if [ ! -f "$localFileName" ] ; then
						echo "$MDSC_CMD: ⛔ ERROR: file is missing: $localFileName, declared at $declaredAt" >&2 
						set +e ; return 1
					fi
					if [ -z "$useVariable" ] ; then
						echo "cp -f 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/$targetPattern'"
						# echo "rsync -rltoD --delete --chmod=ug+rwX 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/$targetPattern' \
						#	2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
					else
						useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
						for useValue in $useValues ; do
							echo "rsync -rltoD --delete --chmod=ug+rwX 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `' \
								2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
						done
					fi
				done
	
			done
	
			##
			## execute path-related patches after processing files
			##
			local sourcePath targetPath scriptSourceName scriptFile matchTargetPath
			echo "$deploySyncFilesTasks" \
			| while read -r sourcePath targetPath; do
	
				[ -z "${deployTargetPatchScripts:0:1}" ] || echo "$deployTargetPatchScripts" \
				| while read -r scriptSourceName scriptFile matchTargetPath; do
					case "${matchTargetPath##/}/" in
						"${targetPath##/}/"*)
							DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/${sourcePath##/}/${matchTargetPath#$targetPath}"
						;;
						*)
							[ "full" != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: 🦠 path skipped: $matchTargetPath ?= $targetPath" >&2
						;;
					esac
				done
	
			done
		fi

		##
		## execute global patches after processing files
		##
		local scriptSourceName scriptFile sourcePath
		ImageInstallProjectDeployPatchScripts --suffix \
		| while read -r scriptSourceName scriptFile sourcePath; do
			DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$sourcePath"
		done

		##
		## sync processed files
		##
		[ -z "${deploySyncFilesTasks:0:1}" ] || echo "$deploySyncFilesTasks" \
		| while read -r sourcePath targetPath; do

			if [ -d "$cacheFolder/sync/$sourcePath" ] ; then
				echo "mkdir -p -m 770 '$targetPath'"
				echo "rsync -iprltOoD --delete --chmod=ug+rwX --exclude='.*' --exclude='.*/' 'sync/$sourcePath/' '$targetPath' \
					2>&1 | (grep --line-buffered -v -E '[\\.>][fd]\\.\\.[t\\.][p\\.][o\\.]\\.+ ' 2>&1 | awk '{print \"> $sourcePath: \"\$0}' | tee -a 'host-files-rsync.log' >&2 || true)"
			else
				echo "mkdir -p -m 770 '$( dirname $targetPath )'"
				echo "rsync -iprltoD --delete --chmod=ug+rwX 'sync/$sourcePath' '$targetPath' \
					2>&1 | (grep --line-buffered -v -E '[\\.>][fd]\\.\\.[t\\.][p\\.][o\\.]\\.+ ' 2>&1 | awk '{print \"> $sourcePath: \"\$0}' | tee -a 'host-files-rsync.log' >&2 || true)"
			fi

		done

		##
		## execute deploy after (deploy applied) script
		##
		#local scriptSourceName scriptFile sourcePath
		ImageInstallProjectDeployPatchScripts --commit \
		| while read -r scriptSourceName scriptFile sourcePath; do
			DistroImageEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "."
		done

	fi

	##
	## check do exec
	##
	if [ "$deployType" != "sync" ] ; then
		[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: building exec script" >&2
		echo 'echo "ImageDeploy: 🙈 executing scripts..." >&2'
		echo 'bash ./exec'
	fi

	echo 'echo "ImageDeploy: 🏁 task finished." >&2'

	##
	## remote host script end
	##
	cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.suffix.include"
	
	echo 'exit 0'
}

DeployProjectsSsh(){
	set -e

	Require ListSshTargets

	type Prefix >/dev/null 2>&1 || \
		. "/usr/local/share/myx.common/bin/lib/prefix"


	local MDSC_CMD='DeployProjectsSsh'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	if [ ! -d "$MMDAPP/output" ] ; then
		if [ ! -d "$MMDAPP/source" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: output folder does not exist: $MMDAPP/output" >&2
			set +e ; return 1
		fi
	fi

	case "$1" in
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default DeployProjectsSsh "$@"
			return 0
		;;
	esac

	local executeSleep="${executeSleep:-true}"
	local explainTasks="${explainTasks:-true}"

	while true ; do
		case "$1" in
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			--no-sleep)
				shift
				executeSleep="false"
			;;
			--non-interactive)
				shift
				executeSleep="false"
				explainTasks="false"
			;;
			*)
				break
			;;
		esac
	done

	local extraArguments="$( local argument ; for argument in "$@" ; do printf '%q ' "$argument" ; done )"

	local taskList="$(
		ListDistroProjects --select-from-env \
			--select-execute-default \
		ListDistroProvides \
			--filter-own-provides-column "deploy-ssh-target:" \
		| while read -r projectName sshTarget ; do
			echo "$projectName" "$sshTarget"
		done
	)"

	if [ -z "$taskList" ] ; then
		echo "No tasks!" >&2
		set +e ; return 1
	fi
	
	echo "Targets selected: " >&2
	local textLine
	echo "$taskList" | while read textLine ; do
		echo "  $textLine" >&2
	done

	local evalList="$(
		echo "$taskList" \
		| while read -r projectName sshTarget ; do
			echo    Prefix "'$sshTarget'" DeployProjectSsh --project "'$projectName'" $extraArguments
		done
	)"

	if [ -z "$evalList" ] ; then
		echo "No tasks!" >&2
		set +e ; return 1
	fi

	if [ "full" = "$MDSC_DETAIL" ] ; then
		echo "Will execute: " >&2
		local textLine
		echo "$evalList" | while read textLine ; do
			echo "  $textLine" >&2
		done
	fi

	if [ "true" = "$executeSleep" ] ; then
		printf "\n%s\n%s\n" \
			"⏳ ...sleeping for 5 seconds..." \
			>&2
		sleep 5
	else
		printf "\n%s\n" \
			"📋 ...executing (--no-sleep)..." \
			>&2
	fi


	trap "trap - SIGTERM && kill -- -$$ >/dev/null 2>&1" SIGINT SIGTERM EXIT

	eval "$evalList"
}

DeployProjectSsh(){

	set -e

	local MDSC_CMD='DeployProjectSsh'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	if [ ! -d "$MMDAPP/output" ] ; then
		if [ ! -d "$MMDAPP/source" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: output folder does not exist: $MMDAPP/output" >&2
			set +e ; return 1
		fi
	fi

	[ "full" != "$MDSC_DETAIL" ] || printf "| $MDSC_CMD: 🔬🦠 \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2

	case "$1" in
		--project)
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default DeployProjectsSsh "$@"
			return 0
		;;
	esac


	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	
	local useSshHost="${useSshHost:-}"
	local useSshPort="${useSshPort:-}"
	local useSshUser="${useSshUser:-}"
	local useSshHome="${useSshHome:-}"
	local useSshArgs="${useSshArgs:-}"

	local prepareFiles="${prepareFiles:-auto}" 
	local prepareScript="${prepareScript:-auto}"

	## not-local 
	executeSleep="${executeSleep:-true}"
	
	local deployType=""

	local MATCH_SCRIPT_FILTER=""

	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			--ssh-host)
				shift ; useSshHost="$1" ; shift
			;;
			--ssh-port)
				shift ; useSshPort="$1" ; shift
			;;
			--ssh-user)
				shift ; useSshUser="$1" ; shift
			;;
			--ssh-home)
				shift ; useSshHome="$1" ; shift
			;;
			--ssh-args)
				shift ; useSshArgs="$1" ; shift
			;;
			--prepare-exec)
				shift
				local prepareScript="true"
			;;
			--prepare-sync)
				shift
				local prepareFiles="true"
			;;
			--prepare-full)
				shift
				local prepareFiles="true"
				local prepareScript="true"
			;;
			--prepare-none)
				shift
				local prepareFiles="false"
				local prepareScript="false"
			;;
			--no-sleep)
				shift
				executeSleep="false"
			;;
			--match)
				shift
				if [ -z "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: match filter expected after --match option" >&2
					set +e ; return 1
				fi
				local MATCH_SCRIPT_FILTER="--match $1"
				shift
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
	
	if [ ! -d "$MDSC_CACHED/$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not found: $MDSC_CACHED/$MDSC_PRJ_NAME" >&2
		set +e ; return 1
	fi
	
	local cacheFolder="$MMDAPP/output/deploy/$MDSC_PRJ_NAME"
	
	mkdir -p "$cacheFolder"
	
	if [ "true" = "$prepareFiles" ] ; then
		echo "$MDSC_CMD: --prepare-sync" >&2
		Require InstallPrepareFiles
		InstallPrepareFiles --project "$MDSC_PRJ_NAME" --save-script "$cacheFolder/sync-prepare-script.txt" --to-directory "$cacheFolder/sync"
		local prepareFiles="auto" 
	fi
	if [ "true" = "$prepareScript" ] ; then
		echo "$MDSC_CMD: --prepare-exec" >&2
		Require InstallPrepareScript
		InstallPrepareScript --project "$MDSC_PRJ_NAME" $MATCH_SCRIPT_FILTER --to-file "$cacheFolder/exec"
		local prepareScript="auto"
	fi
	
	while true ; do
		case "$1" in
			--print-files)
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no options allowed after --print-files option ($@)" >&2
					set +e ; return 1
				fi
				if [ ! -d "$cacheFolder/sync" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no sync folder found ($cacheFolder/sync)" >&2
					set +e ; return 1
				fi
				find "$cacheFolder/sync" -type f | sed "s|^$cacheFolder/sync/||"
				return 0
			;;
			--print-sync-tasks)
				shift
				ImageInstallProjectSyncTasks "$@"
				return 0
			;;
			--print-deploy-patch-scripts)
				shift
				ImageInstallProjectDeployPatchScripts "$@"
				return 0
			;;
			--print-context-variables)
				shift
				DistroImageProjectContextVariables --install "$@"
				return 0
			;;
			--print-installer)
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no options allowed after --print-installer option ($@)" >&2
					set +e ; return 1
				fi
				local outputPath="$cacheFolder/exec"
				if [ "true" = "$prepareScript" ] || [ "auto" = "$prepareScript" -a  ! -f "$outputPath"  ] ; then
					Require InstallPrepareScript
					InstallPrepareScript --project "$MDSC_PRJ_NAME" $MATCH_SCRIPT_FILTER --to-file "$outputPath"
				fi
				if [ ! -f "$outputPath" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no installer script found ($outputPath)" >&2
					set +e ; return 1
				fi
				cat "$outputPath"
				return 0
			;;
			--print-ssh-targets)
				shift
				DistroImageProjectSshTargets "$@"
				return 0
			;;
			--deploy-none)
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no options allowed after --deploy-none option ($@)" >&2
					set +e ; return 1
				fi
				return 0
			;;
			--print-sync-script|--print-exec-script|--print-full-script)
				deployType="${1#"--print-"}"
				deployType="${deployType%"-script"}"
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no options allowed after --deploy-$deployType option ($@)" >&2
					set +e ; return 1
				fi

				executeSleep="false"
				DeployProjectSshInternalPrintRemoteScript
				return 0
			;;
			--save-sync-script|--save-exec-script|--save-full-script)
				deployType="${1#"--save-"}"
				deployType="${deployType%"-script"}"
				shift

				local savedScriptName="$cacheFolder/deploy-script.$deployType.txt"
				[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: building deploy script: $savedScriptName" >&2

				DeployProjectSshInternalPrintRemoteScript > "$savedScriptName.tmp"
				mv -f "$savedScriptName.tmp" "$savedScriptName"

				[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: deploy script ready: $savedScriptName" >&2

				echo "$savedScriptName"
				return 0
			;;
			--deploy-sync|--deploy-exec|--deploy-full)
				local deployType="${1#--deploy-}"
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no options allowed after --deploy-$deployType option ($@)" >&2
					set +e ; return 1
				fi

				DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME

				local projectSshTargets="$( DistroImageProjectSshTargets )"
				if [ -z "${projectSshTargets:0:1}" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no ssh targets found! ($MDSC_PRJ_NAME)" >&2
					set +e ; return 1
				fi

				trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

				local sshTarget
				echo "$projectSshTargets" \
				| while read -r sshTarget; do
					echo "$MDSC_CMD: using ssh: $sshTarget" >&2
					if ! DeployProjectSshInternalPrintRemoteScript \
					| tee "$cacheFolder/deploy-script.$deployType.txt" \
					| bzip2 --best \
					| tee "$cacheFolder/deploy-script.$deployType.txt.bz2" \
					| DistroSshConnect $sshTarget "'bunzip2 | bash'"  ; then
						echo "$MDSC_CMD: ⛔ ERROR: ssh target failed: $sshTarget" >&2
					fi
				done
				return 0
			;;
			'')
				echo "$MDSC_CMD: ⛔ ERROR: --do-XXXX option must be specified" >&2
				set +e ; return 1
			;;
			*)
				echo "$MDSC_CMD: ⛔ ERROR: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	echo "$MDSC_CMD: ⛔ ERROR: oops, not supposed to get here!" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--match <install-script-filter>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}" >&2
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--match <install-script-filter>] --print-{files|sync-tasks|installer|ssh-targets|deploy-patch-scripts|context-variables|full-script}" >&2
			echo "syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.ndm9.net --prepare-sync --deploy-sync" >&2

				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-sync --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-sync --deploy-none" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-none --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-none --deploy-exec" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-exec --deploy-exec" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-full --deploy-full" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-full --print-full-script" >&2

				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.ndm9.net --print-deploy-patch-scripts" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.ndm9.net --print-context-variables" >&2
				
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --ssh-host 192.168.1.17 --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --ssh-port 22 --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --ssh-user guest --prepare-none --print-ssh-targets" >&2
			fi
			exit 1
		fi
		
		DeployProjectSsh "$@"
	;;
esac
