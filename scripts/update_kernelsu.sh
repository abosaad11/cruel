#!/bin/bash
set -e
exec 9>.kernelsu-fetch-lock
flock -n 9 || exit 0
[[ $(( $(date +%s) - $(stat -c %Y "drivers/kernelsu/.check" 2>/dev/null || echo 0) )) -gt 86400 ]] || exit 0

AUTHOR="KernelSU-Next"
REPO="KernelSU-Next"
LATEST_RELEASE=$(curl -s -k "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/releases/latest" | grep -oP '"tag_name": "\K[^"]+')
VERSION=`curl -s -I -k "https://api.github.com/repos/$AUTHOR/$REPO/commits?per_page=1&sha=$LATEST_RELEASE" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p'`

# Latest version fetched from next-susfs branch is always two commit newer than the latest release
#VERSION=`curl -s -I -k "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/commits?per_page=1&sha=next-susfs" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p'`

if [[ -f drivers/kernelsu/.version && *$(cat drivers/kernelsu/.version)* == *$VERSION* ]]; then
	touch drivers/kernelsu/.check
	exit 0
fi

# printf "$REPO updating to $((10000+$VERSION+200))\n"
rm -rf drivers/kernelsu
mkdir -p drivers/kernelsu
cd drivers/kernelsu
# This to get latest version without susfs
wget -q -O - "https://github.com/$AUTHOR/$REPO/archive/refs/tags/$LATEST_RELEASE.tar.gz" | tar -xz --strip=2 "$REPO-${LATEST_RELEASE#v}/kernel"

# This to get latest version with susfs (susfs branch is gone?)
# wget -q -O - "https://github.com/$AUTHOR/$REPO/archive/refs/heads/next-susfs.tar.gz" | tar -xz --strip=2 "$REPO-next-susfs/kernel"
echo $VERSION >> .version
touch .check

# You can patch for your kernel here
echo "" >> Makefile
sed -i '/warning /d' Makefile
sed -i '/DKSU_VERSION/d' Makefile
echo "ccflags-y += -DKSU_VERSION=$((10000 + $VERSION + 200))" >> Makefile
#echo "ccflags-y += -DKSU_VERSION=$((10000 + $VERSION + 198))" >> Makefile
