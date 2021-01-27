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

Require ListProjectProvides

if ! type ImageInstall >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.image-install.include"
fi

DeployProjectSsh(){

	set -e

	[ -z "$MDSC_DETAIL" ] || echo "> DeployProjectSsh $@" >&2
	# [ -z "$MDSC_DETAIL" ] || printf "| DeployProjectSsh: \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2

	if [ ! -d "$MMDAPP/output" ] ; then
		echo "ERROR: DeploySettings: output folder does not exist: $MMDAPP/output" >&2
		return 1
	fi
	
	local useSshHost="${useSshHost:-}"
	local useSshPort="${useSshPort:-}"
	local useSshUser="${useSshUser:-}"
	local useSshClient="${useSshClient:-}"

	local prepareFiles="${prepareFiles:-auto}" 
	local prepareScripts="${prepareScripts:-auto}"

	local executeSleep="${executeSleep:-true}"
	
	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	
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
			--ssh-client)
				shift ; useSshClient="$1" ; shift
			;;
			--prepare-exec)
				shift
				local prepareScripts="true"
			;;
			--prepare-sync)
				shift
				local prepareFiles="true"
			;;
			--prepare-full)
				shift
				local prepareFiles="true"
				local prepareScripts="true"
			;;
			--prepare-none)
				shift
				local prepareFiles="false"
				local prepareScripts="false"
			;;
			--no-sleep)
				shift
				executeSleep="false"
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "ERROR: DeployProjectSsh: project is not selected!" >&2
		return 1
	fi
	
	local cacheFolder="$MMDAPP/output/deploy/$MDSC_PRJ_NAME"
	
	mkdir -p "$cacheFolder"
	
	if [ "true" = "$prepareFiles" ] ; then
		echo "DeployProjectSsh: --prepare-sync" >&2
		Require InstallPrepareFiles
		InstallPrepareFiles --project "$MDSC_PRJ_NAME" --to-directory "$cacheFolder/sync"
		local prepareFiles="auto" 
	fi
	if [ "true" = "$prepareScripts" ] ; then
		echo "DeployProjectSsh: --prepare-exec" >&2
		Require InstallPrepareScript
		InstallPrepareScript --project "$MDSC_PRJ_NAME" --to-file "$cacheFolder/exec"
		local prepareScripts="auto"
	fi
	
	while true ; do
		case "$1" in
			--print-files)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-files option ($@)" >&2
					return 1
				fi
				if [ ! -d "$cacheFolder/sync" ] ; then
					echo "ERROR: DeployProjectSsh: no sync folder found ($cacheFolder/sync)" >&2
					return 1
				fi
				find "$cacheFolder/sync" -type f | sed "s|^$cacheFolder/sync/||"
				return 0
			;;
			--print-sync-tasks)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-sync-tasks option ($@)" >&2
					return 1
				fi

				ImageInstallProjectSyncTasks				
				return 0
			;;
			--print-deploy-patch-scripts)
				shift
				ImageInstallProjectDeployPatchScripts "$@"
				return 0
			;;
			--print-installer)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-installer option ($@)" >&2
					return 1
				fi
				local outputPath="$cacheFolder/exec"
				if [ "true" = "$prepareScripts" ] || [ "auto" = "$prepareScripts" -a  ! -f "$outputPath"  ] ; then
					Require InstallPrepareScript
					InstallPrepareScript --project "$MDSC_PRJ_NAME" --to-file "$outputPath"
				fi
				if [ ! -f "$outputPath" ] ; then
					echo "ERROR: DeployProjectSsh: no installer script found ($outputPath)" >&2
					return 1
				fi
				cat "$outputPath"
				return 0
			;;
			--print-ssh-targets)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-ssh-targets option ($@)" >&2
					return 1
				fi
				
				ListProjectProvides "$MDSC_PRJ_NAME" | grep 'deploy-ssh-target:' | sed 's|deploy-ssh-target:||' \
				| while read -r sshTarget ; do
					local sshSpec="`echo "$sshTarget" | sed 's,^.*@,,'`"
					local sshUser="${useSshUser:-${sshTarget%${sshTarget%@$sshSpec}}}"
					local sshHost="${useSshHost:-`echo "$sshSpec"   | sed 's,:.*$,,'`}"
					local sshPort="${useSshPort:-`echo "$sshSpec"   | sed 's,^.*:,,'`}"
					printf 'ssh %s -p %s -l %s\n' "$sshHost" "$sshPort" "${sshUser:-root}"
				done
				return 0
			;;
			--print-ssh-targets2)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-ssh-targets option ($@)" >&2
					return 1
				fi
				
				DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME
				DistroImageProjectSshTargets
				return 0
			;;
			--deploy-none)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --deploy-none option ($@)" >&2
					return 1
				fi
				return 0
			;;
			--deploy-sync|--deploy-exec|--deploy-full)
				local deployType="${1#--deploy-}"
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --deploy-$deployType option ($@)" >&2
					return 1
				fi

				local projectSshTargets="$( DeployProjectSsh --print-ssh-targets )"
				if [ -z "${projectSshTargets:0:1}" ] ; then
					echo "ERROR: DeployProjectSsh: no ssh targets found!" >&2
					return 1
				fi

				# DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME
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

				[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: building remote script" >&2

				local sshTarget
				echo "$projectSshTargets" \
				| while read -r sshTarget; do
					echo "DeployProjectSsh: using ssh: $sshTarget" >&2
					( \
						##
						## remote host script start
						##

						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.prefix.include"

						if [ "true" = "$executeSleep" ] ; then
							echo 'echo "ImageDeploy: ... sleeping for 5 seconds ..." >&2'
							echo 'sleep 5'
						fi

						##
						## set detailed logging on remote host
						##
						[ -z "$MDSC_DETAIL" ] || echo 'MDSC_DETAIL=true'
						[ "full" != "$MDSC_DETAIL" ] || echo 'set -x'

						echo 'echo "ImageDeploy: uploading..." >&2'

						##
						## embed files needed
						##
						[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: pack deploy files from $cacheFolder/" >&2
						printf "\n( uudecode -p | tar jxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
						tar jcf - -C "$cacheFolder/" "` echo "$deployType" | sed 's|full|sync exec|' `" | uuencode -m packed.tgz
						printf '\nEOF_PROJECT_TAR_XXXXXXXX\n'

						##
						## check do sync
						##
						if [ "$deployType" != "exec" ] ; then
							[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: building sync script" >&2
							echo 'echo "ImageDeploy: syncing files..." >&2'

							##
							## execute global patches before processing files
							##
							local scriptSourceName scriptFile sourcePath
							ImageInstallProjectDeployPatchScripts --prefix \
							| while read -r scriptSourceName scriptFile sourcePath; do
								[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
								ImageInstallEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$sourcePath"
								[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
							done

							##
							## for every sync task
							##
							local sourcePath targetPath
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
											[ -z "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path matched: $matchSourcePath ?= $sourcePath" >&2
											[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
											ImageInstallEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$matchSourcePath"
											[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
										;;
										*)
											[ "full" != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path skipped: $matchSourcePath ?= $sourcePath" >&2
										;;
									esac
								done

								##
								## clone/multiply files
								##
								local declaredAt sourcePath filePath fileName targetPattern useVariable useValues
								echo "$projectProvides" \
								| grep " image-install:clone-deploy-file:$sourcePath:" \
								| tr ':' ' ' | cut -d" " -f1,4- \
								| while read -r declaredAt sourcePath filePath fileName targetPattern useVariable useValues; do
									local localFileName="$cacheFolder/sync/$sourcePath/$filePath/$fileName"
									if [ ! -f "$localFileName" ] ; then
										echo "ERROR: DeployProjectSsh: file is missing: $localFileName, declared at $declaredAt" >&2 
										return 1
									fi
									if [ -z "$useVariable" ] ; then
										echo "rsync -rltoD --delete --chmod=ug+rw 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/$targetPattern' \
											2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
									else
										local useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
										for useValue in $useValues ; do
											echo "rsync -rltoD --delete --chmod=ug+rw 'sync/$sourcePath/$filePath/$fileName' 'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `' \
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
											[ -z "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path matched: $matchTargetPath ?= $targetPath" >&2
											[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$targetPath' >&2"
											ImageInstallEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/${sourcePath##/}/${matchTargetPath#$targetPath}"
											[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$targetPath' >&2"
										;;
										*)
											[ "full" != "$MDSC_DETAIL" ] || echo "PatchScriptFilter: path skipped: $matchTargetPath ?= $targetPath" >&2
										;;
									esac
								done

							done

							##
							## execute global patches after processing files
							##
							local scriptSourceName scriptFile sourcePath
							ImageInstallProjectDeployPatchScripts --suffix \
							| while read -r scriptSourceName scriptFile sourcePath; do
								[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
								ImageInstallEmbedScript "$MMDAPP/source/$scriptSourceName/$scriptFile" "sync/$sourcePath"
								[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$sourcePath' >&2"
							done

							##
							## sync processed files
							##
							echo "$deploySyncFilesTasks" \
							| while read -r sourcePath targetPath; do

								if [ -d "$cacheFolder/sync/$sourcePath" ] ; then
									echo "mkdir -p -m 770 '$targetPath'"
									echo "rsync -iprltoD --delete --chmod=ug+rw --omit-dir-times --exclude='.*' --exclude='.*/' 'sync/$sourcePath/' '$targetPath' \
										2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
								else
									echo "mkdir -p -m 770 '$( dirname $targetPath )'"
									echo "rsync -iprltoD --delete --chmod=ug+rw 'sync/$sourcePath' '$targetPath' \
										2>&1 | (grep -v --line-buffered -E '>f\\.\\.t\\.+ ' >&2 || true)"
								fi

							done
						fi

						##
						## check do exec
						##
						if [ "$deployType" != "sync" ] ; then
							[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: building exec script" >&2
							echo 'echo "ImageDeploy: executing scripts..." >&2'
							echo 'bash ./exec'
						fi

						echo 'echo "ImageDeploy: task finished." >&2'

						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.suffix.include"
						
						exit 0
						##
						## remote host script end
						##
					) | tee "$cacheFolder/deploy-script.$deployType.txt" | bzip2 --best | tee "$cacheFolder/deploy-script.$deployType.txt.bz2" | $sshTarget 'bunzip2 | sudo bash' 
				done
				return 0
			;;
			'')
				echo "ERROR: DeployProjectSsh: --do-XXXX option must be specified" >&2
				return 1
			;;
			*)
				echo "ERROR: DeployProjectSsh: invalid option: $1" >&2
				return 1
			;;
		esac
	done

	echo "ERROR: DeployProjectSsh: oops, not supposed to get here!" >&2
	return 1
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}" >&2
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--prepare-{exec|sync|full|none}] --print-{files|sync-tasks|installer|ssh-targets}" >&2
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