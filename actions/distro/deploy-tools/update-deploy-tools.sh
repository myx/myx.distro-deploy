#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )

cd "$MMDAPP"
export MMDAPP

bash "$MMDAPP/.local/myx/myx.distro-deploy/sh-scripts/DistroDeployTools.fn.sh" --upgrade-deploy-tools
