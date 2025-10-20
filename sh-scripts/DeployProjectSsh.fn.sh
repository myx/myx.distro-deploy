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

type ImageInstall >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.image-install.include"


#[ -n "${TAR_ARGS_GENERIC-}" ] || \
#	. "${MYXROOT:-/usr/local/share/myx.common}/bin/lib/tar.${MYXUNIX:-$( uname -s )}"

[ -n "${TAR_ARGS_GENERIC-}" ] || \
TAR_ARGS_GENERIC=$( printf '%s ' \
	--format=posix \
	--no-xattrs \
	$(if tar --version 2>/dev/null | grep -q GNU; then
		echo --no-acls --no-selinux
	fi) \
	$(if tar --version 2>/dev/null | grep -qi bsdtar; then
		echo --disable-copyfile \
			$( [ "$(uname -s)" != FreeBSD ] || echo --no-mac-metadata )
	fi) \
	--exclude='.DS_Store' \
	--exclude='.AppleDouble' \
	--exclude='Icon?' \
	--exclude='._*' \
	--exclude='.Spotlight-V100' \
	--exclude='.Trashes' \
	--exclude='.git' \
	--exclude='.git/**' \
	--exclude='CVS'
)

##
## Internal - prints script using prepared variables
##
DeployProjectSshInternalPrintRemoteScript(){

	set -e

	local MDSC_CMD="DeployProjectSsh[--print-$deployType-script]"
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2
	
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
	cat "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/ImageDeploy.prefix.include"

	##
	## FIXME: should it be here?
	## insert useful shell functions
	##
	# myx.common cat lib/notifySmart

	echo 'echo "ImageDeploy: 📦 uploading sync files..." >&2'

	##
	## embed files needed
	##
	[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: 📦 pack deploy files from $cacheFolder/" >&2

	# old sender: 
	#   printf '%b' "\n( uudecode -o /dev/stdout | tar -x${compressSetting}f - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
	# old receiver: 
	#   tar -c${compressSetting}f - -C "$cacheFolder/" $( echo "$deployType" | sed 's|full|sync exec|' ) | uuencode -m packed.tbz

	# decode on receiver side
	echo "{ tr -d '\\r' | {"
	echo ' { command -v openssl >/dev/null 2>&1 && {'
	[ -z "$MDSC_DETAIL" ] || \
	echo '    echo "ImageDeploy: 📦 base64: using \"openssl\" to decode" >&2'
	echo '    openssl base64 -d -A 2>/dev/null || openssl enc -base64 -d -A'
	echo ' } } || \'
	echo ' { command -v base64 >/dev/null 2>&1 && {'
	[ -z "$MDSC_DETAIL" ] || \
	echo '    echo "ImageDeploy: 📦 base64: using \"base64\" utility to decode" >&2'
	echo '    base64 --ignore-garbage -d 2>/dev/null || base64 -D'
	echo ' } } || \'
	echo ' { command -v uudecode >/dev/null 2>&1 && {'
	[ -z "$MDSC_DETAIL" ] || \
	echo '    echo "ImageDeploy: 📦 base64: using \"uudecode\" utility to decode" >&2'
	echo '    { printf "begin-base64 644 packed.b64\n"; cat; printf "\n====\nend\n"; } | uudecode -p'
	echo ' } } || \'
	echo ' { echo "⛔ ERROR: can not detect base64 encoder on target machine, make sure: \"openssl\", \"base64\" or \"uuencode\" utility is available" >&2; exit 1; }'
	echo "} | tar -x${compressSetting}f - ; } <<'EOF_PROJECT_TAR_XXXXXXXX'"

	# watch out: $(echo intentionally splits into several arguments!
	# encode on sender side
	tar -c${compressSetting}f - \
		${TAR_ARGS_GENERIC-} \
		-C "$cacheFolder/" \
		$(echo "$deployType" | sed 's|full|sync exec|') \
	| (
		{ command -v openssl	>/dev/null 2>&1 && {
			[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: 📦 base64: using \"openssl\" to encode base64" >&2
			openssl base64 -e -A 2>/dev/null || openssl enc -base64 -A
		} } || \
		{ command -v base64	>/dev/null 2>&1 && {
			[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: 📦 base64: using \"base64\" utility to encode" >&2
			base64 -w0
		} } || \
		{ command -v uuencode	>/dev/null 2>&1 && {
			[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: 📦 base64: using \"uuencode\" utility to encode" >&2
			uuencode -m packed.tbz | sed '1d; /^====$/d'
		} } || \
		{
			echo "$MDSC_CMD: ⛔ ERROR: can't detect base64 encoder, make sure: \"openssl\", \"base64\" or \"uuencode\" utility is available" >&2
			set +e ; return 1
		}
	)

	printf '\nEOF_PROJECT_TAR_XXXXXXXX\n\n'
	# remote script will continue after this
	
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
							[ full != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path skipped: $matchSourcePath ?= $sourcePath" >&2
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
						#	2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || :)"
					else
						useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
						for useValue in $useValues ; do
							echo "rsync -rltoD --delete --chmod=ug+rwX 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `' \
								2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || :)"
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
							[ full != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: 🦠 path skipped: $matchTargetPath ?= $targetPath" >&2
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
				echo "rsync -iprltOoD --delete --delete-excluded --chmod=ug+rwX --exclude='.*' --exclude='.*/' 'sync/$sourcePath/' '$targetPath' 2>&1 \
					| (grep --line-buffered -v -E '[\\.>][fd]\\.\\.[t\\.][p\\.][o\\.]\\.+ ' 2>&1 \
					| awk '{print \"> $sourcePath: \"\$0}' \
					| tee -a 'host-files-rsync.log' >&2 || :)"
			else
				echo "mkdir -p -m 770 '$( dirname $targetPath )'"
				echo "rsync -iprltoD --delete --chmod=ug+rwX 'sync/$sourcePath' '$targetPath' 2>&1 \
					| (grep --line-buffered -v -E '[\\.>][fd]\\.\\.[t\\.][p\\.][o\\.]\\.+ ' 2>&1 \
					| awk '{print \"> $sourcePath: \"\$0}' \
					| tee -a 'host-files-rsync.log' >&2 || :)"
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
	cat "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/ImageDeploy.suffix.include"
	
	echo 'exit 0'
}

DeployProjectsSsh(){
	set -e

	type Prefix >/dev/null 2>&1 || \
		. "${MYXROOT:-/usr/local/share/myx.common}/bin/lib/prefix.Common"

	local MDSC_CMD='DeployProjectsSsh'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
	
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
			Distro ListDistroProjects --select-execute-default DeployProjectsSsh "$@"
			return 0
		;;
	esac

	local executeSleep="${executeSleep:-true}"
	local explainTasks="${explainTasks:-true}"


	# gzip - default, supported in pristine linux
	local compressSetting="${compressSetting:-"z"}" 
	local compressDeflate="${compressDeflate:-"gzip -6"}" 
	local compressInflate="${compressInflate:-"gunzip"}"

	while true ; do
		case "$1" in
			--no-sleep)
				shift
				executeSleep="false"
			;;
			--non-interactive)
				shift
				executeSleep="false"
				explainTasks="false"
			;;
			--use-gzip|--use-gz)
				shift
				compressSetting=z
				compressDeflate='gzip -6'
				compressInflate='gunzip'
			;;
			--use-bzip2|--use-bz2)
				shift
				compressSetting=j
				compressDeflate='bzip2 -6'
				compressInflate='bunzip2'
			;;
			--use-xz)
				shift
				compressSetting=J
				compressDeflate='xz -6'
				compressInflate='unxz'
			;;
			*)
				break
			;;
		esac
	done

	local extraArguments="$( local argument ; for argument in "$@" ; do printf '%q ' "$argument" ; done )"

	local sshTargets="$(
		Distro ListSshTargets --select-from-env \
			--line-prefix '' \
			--line-suffix '' \
			$executeCommand $targetCommand
	)"

	if [ -z "$sshTargets" ] ; then
		echo "No tasks!" >&2
		set +e ; return 1
	fi
	
	echo "> 📋 $MDSC_CMD: Targets selected: " >&2
	local project sshTarget sshOptions
	echo "$sshTargets" | while read -r project sshTarget sshOptions; do
		echo "  > $( basename "$project" ) $sshTarget $( DistroImagePrintSshTarget $sshOptions 2>/dev/null )" >&2
	done \
	2>&1 | column -t 1>&2

	local evalList="$(
		local projectName sshTarget sshOptions
		echo "$sshTargets" \
		| while read -r projectName sshTarget sshOptions ; do
			echo Prefix -o "'$sshTarget'" DeployProjectSsh --project "'$projectName'" --no-sleep $sshOptions $extraArguments
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
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2
	
	if [ ! -d "$MMDAPP/output" ] ; then
		if [ ! -d "$MMDAPP/source" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: output folder does not exist: $MMDAPP/output" >&2
			set +e ; return 1
		fi
	fi

	[ full != "$MDSC_DETAIL" ] || printf "| $MDSC_CMD: 🔬🦠 \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2

	case "$1" in
		--project)
		;;
		--*)
			Distro ListDistroProjects --select-execute-default DeployProjectsSsh "$@"
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

	# gzip - default, supported in pristine linux
	local compressSetting="${compressSetting:-"z"}" 
	local compressDeflate="${compressDeflate:-"gzip -6"}" 
	local compressInflate="${compressInflate:-"gunzip"}"

	local deployType=""

	local MATCH_SCRIPT_FILTER=""

	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			--ssh-name)
				shift 2
			;;
			--ssh-host)
				useSshHost="$2" ; shift 2
			;;
			--ssh-port)
				useSshPort="$2" ; shift 2
			;;
			--ssh-user)
				useSshUser="$2" ; shift 2
			;;
			--ssh-home)
				useSshHome="$2" ; shift 2
			;;
			--ssh-args)
				useSshArgs="$2" ; shift 2
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
				if [ -z "$2" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: filter expected after $1 option" >&2
					set +e ; return 1
				fi
				local MATCH_SCRIPT_FILTER="--match $2"
				shift 2
			;;
			--use-gzip|--use-gz)
				shift
				compressSetting=z
				compressDeflate='gzip -6'
				compressInflate='gunzip'
			;;
			--use-bzip2|--use-bz2)
				shift
				compressSetting=j
				compressDeflate='bzip2 -6'
				compressInflate='bunzip2'
			;;
			--use-xz)
				shift
				compressSetting=J
				compressDeflate='xz -6'
				compressInflate='unxz'
			;;
			*)
				break
			;;
		esac
	done

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

				local projectSshTargets="$( DistroImageProjectSshTargets )"
				if [ -z "${projectSshTargets:0:1}" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: no ssh targets found! ($MDSC_PRJ_NAME)" >&2
					set +e ; return 1
				fi

				trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

				local _ sshOptions
				echo "$projectSshTargets" \
				| while read -r _ _ sshOptions; do
					echo "$MDSC_CMD: using ssh, options: $sshOptions" >&2
					if ! DeployProjectSshInternalPrintRemoteScript \
						| tee "$cacheFolder/deploy-script.$deployType.txt" \
						| ${compressDeflate} \
						| DistroSshConnect $sshOptions -T -o PreferredAuthentications=publickey -o ConnectTimeout=15 "'${compressInflate} | bash'"
					then
						echo "$MDSC_CMD: ⛔ ERROR: ssh target failed, options: $sshOptions" >&2
					fi
				done
				return 0
			;;
			'')
				echo "$MDSC_CMD: ⛔ ERROR: --prepare-XXXX --deploy-XXXX options must be specified" >&2
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
			echo "📘 syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--match <install-script-filter>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}" >&2
			echo "📘 syntax: DeployProjectSsh.fn.sh --project <project> [--match <install-script-filter>] --print-{files|sync-tasks|installer|ssh-targets|deploy-patch-scripts|context-variables|full-script}" >&2
			echo "📘 syntax: DeployProjectSsh.fn.sh --project <project> [--use-bz2|--use-xz] ..." >&2
			echo "📘 syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --prepare-sync --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndss001 --no-sleep --ssh-user root --ssh-home ~/.ssh --prepare-full --deploy-exec" >&2

				echo "    DeployProjectSsh.fn.sh --select-one-project ndns001 --prepare-sync --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-sync --deploy-none" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-none --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-none --deploy-exec" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --prepare-exec --deploy-exec" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --prepare-full --deploy-full" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --prepare-full --print-full-script" >&2

				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --print-deploy-patch-scripts" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.ndm/setup.host-ndns011.example.org --print-context-variables" >&2
				
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --ssh-host 192.168.1.17 --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --select-projects ndns001 --no-sleep --ssh-port 22 --prepare-none --print-ssh-targets" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.example.org --ssh-user guest --prepare-none --print-ssh-targets" >&2
			fi
			exit 1
		fi
		
		DeployProjectSsh "$@"
	;;
esac
