#!/bin/sh -x
arch=`cat /etc/apk/arch`
if [ "$arch" == "aarch64" ] || [ "$arch" == "x86_64" ]; then
  apk add open-vm-tools-hgfs open-vm-tools-vix
  rc-update add open-vm-tools
  echo fuse > /etc/modules-load.d/open-vm-tools.conf
else
  echo "$arch: open-vm-tools is not support 32bit"
fi

if [ "$arch" == "aarch64" ]; then
  if grep -q VMware /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null; then
    # remake /boot/initramfs-virt without mptspi (fusion scsi host)
    if grep -qx linux-virt /etc/apk/world; then
      sed -e 's/ata_piix mptspi sr-mod/ata_piix sr-mod/' -i /usr/share/mkinitfs/initramfs-init
      /sbin/mkinitfs
    fi
  fi
fi                                                              
