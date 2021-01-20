# myx.distro-deploy



image-process, image-install commands:

	image-install:exec-update-before:host/install/<scriptName>
	image-install:exec-update-before:host/install/common-java.sh.txt

	image-install:exec-update-after:host/install/<scriptName>
	image-install:exec-update-after:host/install/common-gctmte.restart.txt

	image-install:deploy-sync-files:<sourceTempPath>:<targetHostPath>
	image-install:deploy-sync-files:data/settings:/usr/local/ndfa/settings

	image-install:deploy-patch-script:<projectName>:host/scripts/<scriptName>
	image-install:deploy-patch-script:.:host/scripts/patch-on-deploy.txt

	--image-install:target-patch-script:<projectName>:host/scripts/<scriptName>:<targetHostPath>
	--image-install:target-patch-script:.:host/scripts/patch-on-deploy.txt:/usr/local/ndns/settings

	--image-install:source-patch-script:<projectName>:host/scripts/<scriptName>:<sourceTempPath>
	--image-install:source-patch-script:.:host/scripts/patch-on-deploy.txt:data/settings
	