# myx.distro-deploy

Default build steps:

	1xxx - source-prepare, source to cached (mode: source, stage: prepare) 
				cached contains all sources required to build changed 
				projects and actual meta-data (distro indices: pre-parsed names, 
				reqires, etc...).
	2xxx - source-process, cached to output (mode: source, stage: prepare)
				output contains and actual meta-data.
	3xxx - image-prepare, output to distro (mode: image, prepare | util)
				distro contains indices and exported items (in their project's locations)
	4xxx - image-process, distro to deploy (prepare | util | install )
				share repositories
	5xxx - image-install, distro to deploy (prepare | util | install )
				deploy tasks are executed upon


Project Files & Folders:

	project.inf - project description file
	actions/** - usable actions (predefined parameters for other scripts)
	source-prepare/builders/* - builders to work on project sets while building source-prepare
	source-process/builders/* - builders to work on project sets while building source-process
	image-prepare/builders/* - builders to work on project sets while building image-prepare
	image-process/builders/* - builders to work on project sets while building image-process
	image-install/builders/* - builders to work on project sets while building image-install
	sh-libs/**
	sh-scripts/**

	
App Folders:

	/
	/source - source codes
	/source/repo[/group]/project - structure
	/cached - build system space
	/cached/sources - synched source for source->distro builders
	/cached/changed - package names that are changed and need to be built
	/cached/built - package names that are built
	/output - output products
	/distro - distro structure (alternative to /source, BTW)


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
	