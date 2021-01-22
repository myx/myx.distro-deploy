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
			--print-folders)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-folders option ($@)" >&2
					return 1
				fi
				return 1
			;;
			--print-files)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-files option ($@)" >&2
					return 1
				fi
				local outputPath="$cacheFolder/sync"
				if [ "true" = "$prepareFiles" ] || [ "auto" = "$prepareFiles" -a  ! -d "$outputPath"  ] ; then
					require InstallPrepareFiles
					InstallPrepareFiles --project "$MDSC_PRJ_NAME" --to-directory "$outputPath"
				fi
				if [ ! -d "$outputPath" ] ; then
					echo "ERROR: DeployProjectSsh: no sync folder found ($outputPath)" >&2
					return 1
				fi
				find "$outputPath" -type f | sed "s|^$outputPath/||"
				return 0
			;;
			--print-sync-tasks)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-sync-tasks option ($@)" >&2
					return 1
				fi
				
				DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME
				
				local projectProvides="$( grep -e "^$MDSC_PRJ_NAME \\S* image-install:" < "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' )"
			
				echo "$projectProvides" \
				| grep " image-install:deploy-sync-files:" | tr ':' ' ' | cut -d" " -f1,4- \
				| while read -r declaredAt sourcePath targetPath ; do
					[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: input: $declaredAt $sourceName $sourcePath $targetPath" >&2
					local fileName="$cacheFolder/sync/$sourcePath"
					if [ ! -d "$fileName" ] ; then
						echo "ERROR: DeployProjectSsh: directory is missing: $fileName, declared at $declaredAt" >&2 
						return 1
					fi
					
					echo "$sourcePath" "$targetPath"
				done \
				| awk '!x[$0]++' 

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

				DistroImageEnsureProvidesMergedFile MDSC_IDAPRV_NAME
				
				local projectProvides="$( grep -e "^$MDSC_PRJ_NAME \\S* image-install:" < "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' )"

				if [ "$deployType" != "exec" ] ; then
					##
					## select sync tasks
					##
					[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: selecting sync tasks" >&2
					local deploySyncFilesTasks="$(
						echo "$projectProvides" \
						| grep " image-install:deploy-sync-files:" | tr ':' ' ' | cut -d" " -f1,4- \
						| while read -r declaredAt sourcePath targetPath ; do
							if [ ! -d "$cacheFolder/sync/$sourcePath" ] ; then
								echo "ERROR: DeployProjectSsh: directory is missing: $cacheFolder/sync/$sourcePath, declared at $declaredAt" >&2 
								return 1
							fi
							echo "$sourcePath" "$targetPath"
						done \
						| awk '!x[$0]++'
					)"
				fi

				[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: building remote script" >&2

				DeployProjectSsh --print-ssh-targets \
				| while read -r sshTarget ; do
					echo "DeployProjectSsh: --deploy-sync, using ssh: $sshTarget" >&2
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

						echo 'echo "ImageDeploy: uploading..." >&2'

						##
						## embed files needed
						##
						[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: pack deploy files from $cacheFolder/" >&2
						printf "\n( uudecode -p | tar zxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
						tar zcf - -C "$cacheFolder/" "` echo "$deployType" | sed 's|full|.|' `" | uuencode -m packed.tgz
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
							echo "$projectProvides" \
							| grep " image-install:source-patch-script:" | tr ':' ' ' | cut -d" " -f1,4- \
							| while read -r declaredAt sourceName scriptFile sourcePath; do
								DistroImageCheckSourcePath --file --project "$MDSC_PRJ_NAME" "$declaredAt" "$sourceName" "$scriptFile" "$sourcePath" \
								| cut -d" " -f2-
							done \
							| awk '!x[$0]++' \
							| while read -r sourceName scriptFile sourcePath; do
								[ -z "$MDSC_DETAIL" ] || echo "echo '> run: image-install:source-patch-script:$sourceName:$scriptFile:$sourcePath' >&2"
								printf "\n\n( cd sync ; uudecode -p | bash ) << 'EOF_PROJECT_SH_XXXXXXXX'\n"
								cat "$MMDAPP/source/$sourceName/$scriptFile" | uuencode -m script.sh
								printf '\nEOF_PROJECT_SH_XXXXXXXX\n\n'
								[ -z "$MDSC_DETAIL" ] || echo "echo '< run: image-install:source-patch-script:$sourceName:$scriptFile:$sourcePath' >&2"
							done

							##
							## for every sync task
							##
							echo "$deploySyncFilesTasks" \
							| while read -r sourcePath targetPath ; do
	
								##
								## execute path-related patches before processing files
								##
								echo "$projectProvides" \
								| grep " image-install:---patch-deploy-files:$sourcePath:" | tr ':' ' ' | cut -d" " -f1,4- \
								| while read -r declaredAt sourcePath filePath fileName targetPattern useVariable useValues ; do
									local localFileName="$cacheFolder/sync/$sourcePath/$filePath/$fileName"
									if [ ! -f "$localFileName" ] ; then
										echo "ERROR: DeployProjectSsh: file is missing: $localFileName, declared at $declaredAt" >&2 
										return 1
									fi
									if [ -z "$useVariable" ] ; then
										echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/$targetPattern'"
									else
										local useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
										for useValue in $useValues ; do
											echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `'"
										done
									fi
								done

								##
								## clone/multiply files
								##
								echo "$projectProvides" \
								| grep " image-install:clone-deploy-file:$sourcePath:" | tr ':' ' ' | cut -d" " -f1,4- \
								| while read -r declaredAt sourcePath filePath fileName targetPattern useVariable useValues ; do
									local localFileName="$cacheFolder/sync/$sourcePath/$filePath/$fileName"
									if [ ! -f "$localFileName" ] ; then
										echo "ERROR: DeployProjectSsh: file is missing: $localFileName, declared at $declaredAt" >&2 
										return 1
									fi
									if [ -z "$useVariable" ] ; then
										echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/$targetPattern'"
									else
										local useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
										for useValue in $useValues ; do
											echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `'"
										done
									fi
								done

								##
								## execute path-related patches after processing files
								##
								echo "$projectProvides" \
								| grep " image-install:---patch-deploy-files:$sourcePath:" | tr ':' ' ' | cut -d" " -f1,4- \
								| while read -r declaredAt sourcePath filePath fileName targetPattern useVariable useValues ; do
									local localFileName="$cacheFolder/sync/$sourcePath/$filePath/$fileName"
									if [ ! -f "$localFileName" ] ; then
										echo "ERROR: DeployProjectSsh: file is missing: $localFileName, declared at $declaredAt" >&2 
										return 1
									fi
									if [ -z "$useVariable" ] ; then
										echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/$targetPattern'"
									else
										local useVariable="` echo "$useVariable" | sed -e 's/[^-A-Za-z0-9_]/\\\\&/g' `"
										for useValue in $useValues ; do
											echo rsync -rltoD --delete --chmod=ug+rw "'sync/$sourcePath/$filePath/$fileName'" "'sync/$sourcePath/$filePath/` echo "$targetPattern" | sed "s:$useVariable:$useValue:" `'"
										done
									fi
								done
							done

							##
							## execute global patches after processing files
							##
							echo "$projectProvides" \
							| grep " image-install:deploy-patch-script:" | tr ':' ' ' | cut -d" " -f1,4- \
							| while read -r declaredAt sourceName scriptFile sourcePath; do
								DistroImageCheckSourcePath --file --project "$MDSC_PRJ_NAME" "$declaredAt" "$sourceName" "$scriptFile" "$sourcePath" \
								| cut -d" " -f2-
							done \
							| awk '!x[$0]++' \
							| while read -r sourceName scriptFile sourcePath; do
								[ -z "$MDSC_DETAIL" ] || echo "echo '> run: image-install:deploy-patch-script:$sourceName:$scriptFile:$sourcePath' >&2"
								printf "\n\n( cd "sync/$sourcePath" ; uudecode -p | bash ) << 'EOF_PROJECT_SH_XXXXXXXX'\n"
								cat "$MMDAPP/source/$sourceName/$scriptFile" | uuencode -m script.sh
								printf '\nEOF_PROJECT_SH_XXXXXXXX\n\n'
								[ -z "$MDSC_DETAIL" ] || echo "echo '< run: image-install:deploy-patch-script:$sourceName:$scriptFile:$sourcePath' >&2"
							done

							##
							## sync processed files
							##
							echo "$deploySyncFilesTasks" \
							| while read -r sourcePath targetPath ; do
	
								if [ -d "$cacheFolder/sync/$sourcePath" ] ; then
									echo "mkdir -p -m 770 '$targetPath'"
									echo "rsync -iprltoD --delete --chmod=ug+rw --omit-dir-times --exclude='.*' --exclude='.*/' 'sync/$sourcePath/' '$targetPath'"
								else
									echo "rsync -iprltoD --delete --chmod=ug+rw 'sync/$sourcePath' '$targetPath'"
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
						
						##
						## remote host script end
						##
					) | $sshTarget sudo bash 
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