#!/bin/bash
# Run a fast volume check on large Time Machine backup disks

export VOLUME="/Volumes/$1"
echo "Determining disk device of $VOLUME"

export DISK=`diskutil info $VOLUME | sed -n '/ Device Node\:/s/.* \(\/dev\/disk.*\).*/\1/p'`

if [ "$DISK" = "" ]; then
  echo "Unable to determine device name!"
  exit 1
fi
echo "Performing filesystem check on $DISK"
diskutil unmountDisk $DISK
# https://www.unix.com/man-page/osx/8/fsck_hfs/
sudo fsck_hfs -fy -c 2g /dev/rdisk2s3
#sudo fsck_hfs -d -fy -c 2g $DISK
diskutil mountDisk $DISK
