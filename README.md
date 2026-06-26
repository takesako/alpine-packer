# alpine-packer

packer build scripts for making Alpine Linux boxes (x86_64/aarch64) by virtualbox-iso, vmware-iso.

## Vagrant Cloud boxes (built by alpine-packer)

- https://app.vagrantup.com/takesako/boxes/alpine-standard-v3.19
- https://app.vagrantup.com/takesako/boxes/alpine-virt-v3.24

## create latest pkrvars.hcl

```perl perl-iso2hcl.pl v3.24```

## bulild for Intel x86_64 (virtualbox provider)

```packer plugins install github.com/hashicorp/virtualbox```

```packer build -var-file=alpine-standard/alpine-standard-3.24.1-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.24.1-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl```

## bulild for Intel x86_64 (vmware_desktop provider)

```packer plugins install github.com/vmware/vmware```

```packer build -var-file=alpine-standard/alpine-standard-3.24.1-x86_64.pkrvars.hcl vmware-iso.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.24.1-x86_64.pkrvars.hcl vmware-iso.pkr.hcl```

## bulild for Apple Silicon M1/M2 Mac (vmware_desktop provider)

```packer plugins install github.com/vmware/vmware```

```packer build -var-file=alpine-standard/alpine-standard-3.24.1-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl```

```packer build -var-file=alpine-virt/alpine-virt-3.24.1-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl```

