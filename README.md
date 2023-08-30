# alpine-packer
packer build scripts for making Alpine Linux boxes (x86_64/aarch64) by virtualbox-iso, vmware-iso.

## for Intel x86_64 (virtualbox and vmware_fusion provider)

```packer build -var-file=alpine-virt-3.18.3-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl```

```packer build -var-file=alpine-virt-3.18.3-x86_64.pkrvars.hcl vmware-iso.pkr.hcl```

- https://app.vagrantup.com/takesako/boxes/alpine-virt-3.18-x86_64

## for Apple Silicon M1/M2 Mac (vmware_fusion provider)

```packer build -var-file=alpine-virt-3.18.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl```

- https://app.vagrantup.com/takesako/boxes/alpine-virt-3.18-aarch64

