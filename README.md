# myx.distro-deploy

Default build steps (order in which operations are performed. Source: 1..3, Distro: 4..5):

	1xxx - source-prepare, source to cached (mode: source, stage: prepare) 
				cached contains all sources required to build changed 
				projects and actual meta-data (distro indices: pre-parsed names, 
				reqires, etc...).
	2xxx - source-process, cached to output (mode: source, stage: prepare)
				output contains all actual meta-data.
	3xxx - image-prepare, output to distro (mode: image, prepare | util)
				distro contains indices and exported items (in their project's locations)
	4xxx - image-process, distro to deploy (prepare | util | install )
				share repositories
	5xxx - image-install, distro to deploy (prepare | util | install )
				deploy tasks are executed upon


Project Files & Folders (following masks have fixed meaning in the root folder of each project):

	project.inf - project description file
	actions/** - usable actions (predefined parameters for other scripts)
	source-prepare/builders/1???-* - builders to work on project sets while building source-prepare
	source-process/builders/2???-* - builders to work on project sets while building source-process
	image-prepare/builders/3???-* - builders to work on project sets while building image-prepare
	image-process/builders/4???-* - builders to work on project sets while building image-process
	image-install/builders/5???-* - builders to work on project sets while building image-install
	sh-libs/**
	sh-scripts/**

Builders Examples (actual builders, relative to the root of the workspace):

	source/myx/myx.distro-source/source-prepare/builders/1000-env-from-source.sh
	source/myx/myx.distro-source/source-process/builders/2000-env-from-cached.sh
	source/myx/myx.distro-source/source-process/builders/2899-output-ready.sh
	source/myx/myx.distro-source/image-prepare/builders/3899-distro-ready.sh
	source/myx/myx.distro-distro/image-process/builders/4911-deploy-apply.sh
	source/myx/myx.distro-distro/image-install/builders/5911-deploy-apply.sh

Variables (context environment) available in: actions, build-step scripts and console (deploy mode):

	MMDAPP - workspace root (something like: "/Volumes/ws-2017/myx-work")
	MDSC_INMODE - cosole mode ("distro")
	MDSC_ORIGIN - primary source of console commands (something like: "/Volumes/ws-2017/myx-work/source/myx/myx.distro-deploy/sh-lib")
	MDSC_OPTION - console mode settings (something like: "--distro-from-output")
	MDSC_SOURCE - current source root (something like: "/Volumes/ws-2017/myx-work/output/distro")
	MDSC_CACHED - current cache root (something like: "/Volumes/ws-2017/myx-work/cached")
	MDSC_OUTPUT - current target root (something like: "/Volumes/ws-2017/myx-work/output/distro")
	MDSC_DETAIL - debug settings, values: <empty>, "true", "full"
	useSshUser - override from ssh user calculated from project sequence variables
	useSshHome - override from ssh home calculated from project sequence variables
	useSshArgs - extra arguments for ssh conection (something like: "-o ForwardAgent=yes -o AddKeysToAgent=yes")

Variables (context environment) specific to build-step scripts:

	BUILD_STAMP - current build timestamp (build steps only)

App Folders:

	/ - workspace root directory
	/source - source codes and projects - editable and commitable or pullable
	/cached - build system cache space (generated)
	/output - output products (generated, cloned or omitted (in pure deploy mode))
	/export - export resources (generated or cloned)
	/distro - distro structure, whole project tree, prepared (generated or cloned)
	/distro/repo[/group]/project - project folders structure
	/distro/repository-names.txt - repository names db file (prepared)
	/distro/build-time-stamp.txt - distro timestamp file (prepared)
	/distro/distro-index.inf - distro index shell-env file (prepared)
	/actions - workspace actions - non-editable (generated)

image-receive, image-install commands:

	image-install:context-variable:
		image-install:context-variable:<variableName>:{create|change|ensure|insert|update|remove|re-set|delete}[:<valueNoSpaces>...]
		image-install:context-variable:<variableName>:{create|change|ensure|append|update|remove|define|delete}[:<valueNoSpaces>...]
		image-install:context-variable:<variableName>:{import|source}:{.|<projectName>}:<scriptPath>

		image-install:context-variable:DPL_HOST_TYPE:re-set:standalone
		image-install:context-variable:DPL_HOST_TYPE:change:guest
		image-install:context-variable:DPL_HOST_TYPE:delete
		image-install:context-variable:DPL_LANGUAGES:update:en
		image-install:context-variable:DPL_LANGUAGES:create:en
		image-install:context-variable:DPL_LANGUAGES:insert:ru
		image-install:context-variable:DPL_LANGUAGES:insert:lv
		image-install:context-variable:DPL_LANGUAGES:remove:lv
		image-install:context-variable:DPL_LANGUAGES:import:.:ssh/rsa.pub
		image-install:context-variable:DPL_LANGUAGES:source:.:ssh/rsa.pub

		^^^ <sourceName> '.' - this (declarant) project's source


	image-install:exec-update-before:
		image-install:exec-update-before:host/install/<scriptName>
		
		image-install:exec-update-before:host/install/common-java.sh.txt

	image-install:exec-update-after:
		image-install:exec-update-after:host/install/<scriptName>
		
		image-install:exec-update-after:host/install/common-gctmte.restart.txt

	image-install:deploy-patch-script-prefix:
		image-install:deploy-patch-script-prefix:<scriptSourceName>:host/scripts/<scriptName>[:relativePath]

		image-install:deploy-patch-script-prefix:.:host/scripts/patch-on-before-deploy.txt

	image-install:deploy-sync-files:
		image-install:deploy-sync-files:<deploySourcePath>:<targetHostPath>

		image-install:deploy-sync-files:data/settings:/usr/local/ndfa/settings

	image-install:source-patch-script:
		image-install:source-patch-script:<deploySourcePath>:<scriptSourceName>:host/scripts/<scriptName>

		image-install:source-patch-script:data/settings:.:host/scripts/patch-on-deploy.txt

	image-install:clone-deploy-file:
		image-install:clone-deploy-file:<deploySourcePath>:<sourceFileName>:<targetNamePattern>[:<variableName>:<valueX...>]

		image-install:clone-deploy-file:data/settings:web/default:page-200.html:page-???.html:???:201:204 \
		image-install:clone-deploy-file:data/settings:web/default:page-404.html:page-418.html \

	image-install:target-patch-script:
		image-install:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetHostPath>

		image-install:target-patch-script:.:host/scripts/patch-on-deploy.txt:/usr/local/ndns/settings

	image-install:deploy-patch-script:
		image-install:deploy-patch-script:<scriptSourceName>:host/scripts/<scriptName>[:relativePath]

		image-install:deploy-patch-script:.:host/scripts/patch-on-deploy.txt
	
	image-install:deploy-patch-script-suffix:
		image-install:deploy-patch-script-suffix:<scriptSourceName>:host/scripts/<scriptName>[:relativePath]

		image-install:deploy-patch-script-suffix:.:host/scripts/patch-at-remote-on-after-deploy-prepared.txt
	
	image-install:deploy-applied-script:
		image-install:deploy-applied-script:<scriptSourceName>:host/scripts/<scriptName>[:relativePath]

		image-install:deploy-applied-script:.:host/scripts/at-remote-on-after-deploy.txt
	