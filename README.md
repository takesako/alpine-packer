# alpine-packer

packer build scripts for making Alpine Linux boxes (x86_64/aarch64) by virtualbox-iso, vmware-iso.

## for Intel x86_64 (virtualbox provider)

```packer build -var-file=alpine-standard/alpine-standard-3.18.4-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.18.4-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl```


## for Intel x86_64 (vmware provider)

```packer build -var-file=alpine-standard/alpine-standard-3.18.4-x86_64.pkrvars.hcl vmware-iso.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.18.4-x86_64.pkrvars.hcl vmware-iso.pkr.hcl```

## for Apple Silicon M1/M2 Mac (vmware_fusion provider)

```packer build -var-file=alpine-standard/alpine-standard-3.18.4-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.18.4-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl```

# Vagrant Cloud boxes (built by alpine-packer)

- https://app.vagrantup.com/takesako/boxes/alpine-standard-v3.18
- https://app.vagrantup.com/takesako/boxes/alpine-virt-v3.18

