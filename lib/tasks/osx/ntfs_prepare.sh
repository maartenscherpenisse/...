#!/usr/bin/env bash
#
# NTFS-3G functions

source ./lib/utilities.sh

ntfs_prepare () {
  if csrutil status | grep "System Integrity Protection status: disabled"; then
    echo "System Integrity Protection status: disabled."
    if [ -f /sbin/mount_ntfs ]; then
      cached_sudo mv /sbin/mount_ntfs /sbin/mount_ntfs.original
    fi
    cached_sudo ln -sf /usr/local/sbin/mount_ntfs /sbin/mount_ntfs
  else
    echo "System Integrity Protection status: enabled."
    echo "(ERROR: SIP Enabled)" >&3
    return 72
  fi
}

ntfs_prepare
