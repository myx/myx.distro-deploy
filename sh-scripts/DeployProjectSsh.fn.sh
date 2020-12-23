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

Require ListProjectProvides

DeployProjectSsh(){
	set -e

	[ -z "$MDSC_DETAIL" ] || echo "> DeployProjectSsh $@" >&2

	if [ ! -d "$MMDAPP/output" ] ; then
		echo "ERROR: DeploySettings: output folder does not exist: $MMDAPP/output" >&2
		return 1
	fi
	
	if [ "$1" != "--project" ] ; then
		echo "ERROR: DeployProjectSsh: '--project' argument is required!" >&2
		return 1
	fi
	shift

	local projectName="$1" ; shift
	if [ -z "$projectName" ] ; then
		echo "ERROR: DeployProjectSsh: 'projectName' argument is required!" >&2
		return 1
	fi

	local doFiles="${doFiles:-auto}" 
	local doScripts="${doScripts:-auto}"
	local doSshHost="${doSshHost:-}"
	local doSshPort="${doSshPort:-}"
	local doSshUser="${doSshUser:-}"
	local doSshClient="${doSshClient:-}"
	local doSleep="${doSleep:-true}"
	
	while true ; do
		case "$1" in
			--prepare-exec)
				shift
				local doScripts="true"
			;;
			--prepare-sync)
				shift
				local doFiles="true"
			;;
			--prepare-full)
				shift
				local doFiles="true"
				local doScripts="true"
			;;
			--prepare-none)
				shift
				local doFiles="false"
				local doScripts="false"
			;;
			--no-sleep)
				shift
				doSleep="false"
			;;
			--ssh-host)
				shift
				doSshHost="$1" ; shift
			;;
			--ssh-port)
				shift
				doSshPort="$1" ; shift
			;;
			--ssh-user)
				shift
				doSshUser="$1" ; shift
			;;
			--ssh-client)
				shift
				doSshClient="$1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	local cacheFolder="$MMDAPP/output/deploy/$projectName"
	
	mkdir -p "$cacheFolder"
	
	if [ "true" = "$doFiles" ] ; then
		echo "DeployProjectSsh: --prepare-sync" >&2
		Require InstallPrepareFiles
		InstallPrepareFiles "$projectName" --to-directory "$cacheFolder/sync"
		local doFiles="auto" 
	fi
	if [ "true" = "$doScripts" ] ; then
		echo "DeployProjectSsh: --prepare-exec" >&2
		Require InstallPrepareScript
		InstallPrepareScript "$projectName" --to-file "$cacheFolder/exec"
		local doScripts="auto"
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
				local outputPath="$MMDAPP/output/deploy/$projectName/sync"
				if [ "true" = "$doFiles" ] || [ "auto" = "$doFiles" -a  ! -d "$outputPath"  ] ; then
					require InstallPrepareFiles
					InstallPrepareFiles "$projectName" --to-directory "$outputPath"
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
				
				Require ListDistroProvides
				local allProvides="`ListDistroProvides --all-provides-merged`"
			
				echo "$allProvides" | grep "^$projectName " | cut -d" " -f2,3 \
				| grep " image-install:deploy-sync-files:" | tr ':' ' ' | cut -d" " -f1,4- \
				| while read -r declaredAt sourcePath targetPath ; do
					[ -z "$MDSC_DETAIL" ] || echo "DeployProjectSsh: input: $declaredAt $sourceName $sourcePath $mergePath" >&2
					local fileName="$MMDAPP/output/deploy/$projectName/sync/$sourcePath"
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
				local outputPath="$MMDAPP/output/deploy/$projectName/exec"
				if [ "true" = "$doScripts" ] || [ "auto" = "$doScripts" -a  ! -f "$outputPath"  ] ; then
					Require InstallPrepareScript
					InstallPrepareScript "$projectName" --to-file "$outputPath"
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
				
				ListProjectProvides "$projectName" | grep 'deploy-ssh-target:' | sed 's|deploy-ssh-target:||' | while read -r sshTarget ; do
					local sshSpec="`echo "$sshTarget" | sed 's,^.*@,,'`"
					local sshUser="${doSshUser:-${sshTarget%${sshTarget%@$sshSpec}}}"
					local sshHost="${doSshHost:-`echo "$sshSpec"   | sed 's,:.*$,,'`}"
					local sshPort="${doSshPort:-`echo "$sshSpec"   | sed 's,^.*:,,'`}"
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
			--deploy-sync)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --deploy-sync option ($@)" >&2
					return 1
				fi

				DeployProjectSsh --project "$projectName" --print-ssh-targets | while read -r sshTarget ; do
					echo "DeployProjectSsh: --deploy-sync, using ssh: $sshTarget" >&2
					( \
						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.prefix.include"

						if [ "true" = "$doSleep" ] ; then
							echo 'echo "ImageDeploy: ... sleeping for 5 seconds ..." >&2'
							echo 'sleep 5'
						fi

						echo 'echo "ImageDeploy: uploading..." >&2'

						printf "\n( uudecode -p | tar zxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
						tar zcf - -C "$MMDAPP/output/deploy/$projectName/sync/" . | uuencode -m packed.tgz 
						printf '\nEOF_PROJECT_TAR_XXXXXXXX\n'

						echo 'echo "ImageDeploy: syncing files..." >&2'

						DeployProjectSsh --project "$projectName" --print-sync-tasks | while read -r sourcePath targetPath ; do
							echo "mkdir -p -m 770 '$targetPath'"
							echo "rsync -iprltoD --delete --chmod=ug+rw --omit-dir-times './$sourcePath/' '$targetPath'"
						done

						echo 'echo "ImageDeploy: task finished." >&2'

						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.suffix.include"
					) | $sshTarget sudo bash 
				done
				return 0
			;;
			--deploy-full)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --deploy-full option ($@)" >&2
					return 1
				fi

				DeployProjectSsh --project "$projectName" --print-ssh-targets | while read -r sshTarget ; do
					echo "DeployProjectSsh: --deploy-full, using ssh: $sshTarget" >&2
					( \
						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.prefix.include"

						if [ "true" = "$doSleep" ] ; then
							echo 'echo "ImageDeploy: ... sleeping for 5 seconds ..." >&2'
							echo 'sleep 5'
						fi

						echo 'echo "ImageDeploy: uploading..." >&2'

						printf "\n( uudecode -p | tar zxf - ) << 'EOF_PROJECT_TAR_XXXXXXXX'\n"
						tar zcf - -C "$MMDAPP/output/deploy/$projectName/" . | uuencode -m packed.tgz 
						printf '\nEOF_PROJECT_TAR_XXXXXXXX\n'

						echo 'echo "ImageDeploy: syncing files..." >&2'

						DeployProjectSsh --project "$projectName" --print-sync-tasks | while read -r sourcePath targetPath ; do
							echo "mkdir -p -m 770 '$targetPath'"
							echo "rsync -iprltoD --delete --chmod=ug+rw --omit-dir-times './sync/$sourcePath/' '$targetPath'"
						done

						echo 'echo "ImageDeploy: executing scripts..." >&2'

						echo 'bash ./exec'

						echo 'echo "ImageDeploy: task finished." >&2'

						cat "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/ImageDeploy.suffix.include"
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

	local sshTarget="`ListProjectProvides "$projectName" --print-provides-only --filter-and-cut deploy-ssh-target`"
	if [ -z "$sshTarget" ] ; then
		echo "ERROR: DeployProjectSsh: $projectName does not have ssh target set!" >&2
		return 1
	fi
	
	local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
	local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
	
	# ssh $sshHost -p $sshPort "$@"
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--prepare-{exec|sync|full|none}] --deploy-{sync|exec|full|none}" >&2
			echo "syntax: DeployProjectSsh.fn.sh --project <project> [--ssh-{host|port|user|client} <value>] [--prepare-{exec|sync|full|none}] --print-{files|sync-tasks|installer|ssh-targets}" >&2
			echo "syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-sync --deploy-sync" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-sync --deploy-none" >&2
				echo "    DeployProjectSsh.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --prepare-none --deploy-sync" >&2
				
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