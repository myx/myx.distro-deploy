
echo "Rebuilding 'source' KnownHosts (merge with current known hosts)..." >&2

DistroSystemContext --distro-from-source
Distro RebuildKnownHosts --no-delete
