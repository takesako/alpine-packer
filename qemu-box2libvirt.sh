#!/bin/sh
curl -L -O https://vagrantcloud.com/takesako/boxes/alpine-virt-3.24-aarch64/versions/3.24.1/providers/libvirt/aarch64/vagrant.box
mkdir box
tar xf vagrant.box -C box
mkdir libvirt
qemu-img convert -p -O qcow2 box/*.vmdk libvirt/qcow2.img
cat > libvirt/metadata.json <<'EOF'
{
  "provider": "libvirt",
  "format": "qcow2",
  "architecture": "aarch64",
  "virtual_size": 8
}
EOF
touch libvirt/Vagrantfile
tar cf - -C libvirt . | gzip -9 > libvirt.box
