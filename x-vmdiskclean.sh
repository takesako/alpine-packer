#!/bin/sh -x
# vmdiskclean
rm -f /var/cache/apk/*
rm -f /var/log/* /var/log/*/*
rm -f /home/*/.ash_history
rm -f /root/.ash_history
rm -f /etc/resolv.conf
dd if=/dev/zero of=/boot/zero bs=8K status=progress
rm -f /boot/zero
dd if=/dev/zero of=/zero bs=16M status=progress
rm -f /zero
