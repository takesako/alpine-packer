#!/bin/sh -xe

# keymap
setup-keymap jp jp
setup-keymap us us

# apk login boot
echo "Welcome to Alpine Linux!" > /etc/motd
if test -e /boot/extlinux.conf; then
  sed -i -e 's/TIMEOUT [0-9]\+/TIMEOUT 1/' /boot/extlinux.conf
  sed -i -e 's/PROMPT 0/PROMPT 1/' /boot/extlinux.conf
fi

# for Arch Linux ssh client
echo 'KbdInteractiveAuthentication no' >> /etc/ssh/sshd_config

# inittab
sed -r "s;^(ttyS0:.*);#\1;g" -i /etc/inittab

# mdev.conf
sed -i "s/ttyUSB/ttyACM[0-9]\troot:dialout 0660 @ln -sf \$MDEV modem\nttyUSB/;" /etc/mdev.conf

# profile
echo "umask 002" > /etc/profile.d/umask
echo -e "#!/bin/sh\nsudo poweroff\n" > /sbin/shutdown
chmod 755 /sbin/shutdown

# ssh
cd /home/vagrant
chmod 2755 .
mkdir -m 700 .ssh
wget https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
mv vagrant.pub .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
chown vagrant:vagrant .ssh .ssh/*

# bash
apk add bash

# sudo
apk add sudo
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 400 /etc/sudoers.d/vagrant

# doas
apk add doas
echo 'permit nopass :wheel' > /etc/doas.d/wheel.conf
chmod 400 /etc/doas.d/wheel.conf
addgroup vagrant wheel

# random
apk add haveged
rc-update add haveged
##apk add rng-tools
##rc-update add rngd
##cat /proc/sys/kernel/random/entropy_avail

# mount
cd /home/vagrant
mkdir -m 777 /vagrant
chown vagrant:vagrant /vagrant
VUID=`id -u vagrant`
VGID=`id -g vagrant`
cat<<EOF>.profile
#!/bin/sh
if grep -q -E "vboxsf.*uid=0,gid=0" /proc/mounts ; then
  sudo umount /vagrant
  sudo mount.vboxsf -o uid=$VUID,gid=$VGID,rw vagrant /vagrant
fi
EOF
chmod 755 .profile
chown vagrant:vagrant .profile

