# alpine-packer

packer build scripts for making Alpine Linux boxes (x86_64/aarch64) by virtualbox-iso, vmware-iso.

## Vagrant Cloud boxes (built by alpine-packer)

- https://app.vagrantup.com/takesako/boxes/alpine-standard-v3.19
- https://app.vagrantup.com/takesako/boxes/alpine-virt-v3.19

## build for Intel x86_64 (virtualbox provider)

```sh
packer build -var-file=alpine-standard/alpine-standard-3.21.3-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl
```

```sh
packer build -var-file=alpine-virt/alpine-virt-3.21.3-x86_64.pkrvars.hcl virtualbox-iso.pkr.hcl
```


## build for Intel x86_64 (vmware provider)

```sh
packer build -var-file=alpine-standard/alpine-standard-3.21.3-x86_64.pkrvars.hcl vmware-iso.pkr.hcl
```

```sh
packer build -var-file=alpine-virt/alpine-virt-3.21.3-x86_64.pkrvars.hcl vmware-iso.pkr.hcl
```

## build for Apple Silicon M1/M2/M3 Mac (vmware_fusion provider)

```sh
packer build -var-file=alpine-standard/alpine-standard-3.21.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl
```

```sh
packer build -var-file=alpine-virt/alpine-virt-3.21.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl
```
