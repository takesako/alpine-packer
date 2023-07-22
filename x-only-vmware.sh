#!/bin/sh -x
arch=`cat /etc/apk/arch`
if [ "$arch" == "aarch64" ] || [ "$arch" == "x86_64" ]; then
  apk add open-vm-tools-hgfs open-vm-tools-guestinfo
  rc-update add open-vm-tools
  echo fuse > /etc/modules-load.d/open-vm-tools.conf
else
  echo "$arch: open-vm-tools is not support 32bit"
fi
