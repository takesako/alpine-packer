variable "iso_url" {
  type    = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-standard-3.18.3-x86_64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:badeb7f57634c22dbe947bd692712456f2daecd526c14270355be6ee5e73e83e"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.18.3-x86_64"
}

variable "guest_os_type_virtualbox" {
  type    = string
  default = "not supported"
}

variable "guest_os_type_vmware" {
  type    = string
  default = "other5xlinux-64"
}

variable "install_dev" {
  type    = string
  default = "/dev/sda"
}

variable "msys_dev" {
  type    = string
  default = "/dev/sda3"
}

variable "root_password" {
  type    = string
  default = "vagrant"
}

variable "vagrant_password" {
  type    = string
  default = "vagrant"
}

# https://developer.hashicorp.com/packer/plugins/builders/vmware/iso
source "vmware-iso" "alpine" {
  vm_name              = "${var.vm_name}"
  communicator         = "ssh"
  cdrom_adapter_type   = "ide"
  disk_size            = "8192"
  disk_adapter_type    = "scsi"
  format               = "vmx"
  guest_os_type        = "${var.guest_os_type_vmware}"
  headless             = false
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  keep_registered      = true
  output_directory     = "output-${var.vm_name}"
  shutdown_command     = "/sbin/poweroff"
  skip_compaction      = false
  skip_export          = true
  ssh_password         = "${var.root_password}"
  ssh_timeout          = "3m"
  ssh_username         = "root"
  usb                  = true
  vmx_data             = {
	"memsize" = "256"
	"numvcpus" = "2"
	"virtualhw.version" = "8"
	"bios.bootorder" = "hdd,cdrom"
	"bios.hddorder" = "scsi0:0"
	"tools.synctime" = "FALSE"
	"time.synchronize.continue" = "FALSE"
	"time.synchronize.restore" = "FALSE"
	"time.synchronize.resume.disk" = "FALSE"
	"time.synchronize.shrink" = "FALSE"
	"time.synchronize.tools.startup" = "FALSE"
	"time.synchronize.tools.enable" = "FALSE"
	"time.synchronize.resume.host" = "FALSE"
	"usb.present" = "TRUE"
	"ehci.present" = "TRUE"
	"usb_xhci.present" = "TRUE"
	"usb.vbluetooth.startconnected" = "TRUE"
	"ethernet0.virtualdev" = "vmxnet3"
	"scsi0.present" = "TRUE"
	"floppy0.present" = "FALSE"
	"cleanshutdown" = "TRUE"
	"softpoweroff" = "TRUE"
  }
  vmx_data_post        = {
	"ide0:0.startconnected" = "FALSE"
  }
  vmx_remove_ethernet_interfaces = true
  boot_key_interval    = "13ms"
  boot_wait            = "20s"
  boot_command         = [<<EOF
	root<enter><wait>
	date -u -s ${formatdate("YYYYMMDDhhmm.ss", timestamp())}<enter><wait>
	hwclock -u -w<enter><wait>
	cat<<EOA>answers<enter>
	KEYMAPOPTS="us us"<enter>
	HOSTNAMEOPTS=alpine<enter>
	DEVDOPTS=mdev<enter>
	INTERFACESOPTS="auto lo<enter>
	iface lo inet loopback<enter>
	<enter>
	auto eth0<enter>
	iface eth0 inet dhcp<enter>
	    hostname alpine<enter>
	"<enter>
	DNSOPTS="-d example.com 8.8.8.8"<enter>
	TIMEZONEOPTS=UTC<enter>
	PROXYOPTS=none<enter>
	APKREPOSOPTS=-1<enter>
	USEROPTS="-a -u -g audio,video,netdev,dialout vagrant"<enter>
	SSHDOPTS=openssh<enter>
	NTPOPTS=busybox<enter>
	DISKOPTS="-m sys ${var.install_dev}"<enter>
	EOA<enter><wait>
	setup-alpine -f answers<enter><wait10>
	${var.root_password}<enter><wait1>
	${var.root_password}<enter><wait20s>
	y<enter><wait20s>
	mount ${var.msys_dev} /mnt<enter><wait>
	echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter><wait>
	umount /mnt<enter><wait1>
	reboot<enter><wait1>
	EOF
	]
}

build {
  sources = [
    "source.vmware-iso.alpine"
  ]
  provisioner "shell" {
    inline = [
      "echo 'vagrant:${var.vagrant_password}' | chpasswd",
      "sed '/PermitRootLogin yes/d' -i /etc/ssh/sshd_config"
    ]
  }
  provisioner "shell" {
    scripts = [
      "x-apk-update.sh",
      "x-only-vmware.sh",
      "x-provision.sh",
      "x-vmdiskclean.sh"
    ]
  }
  post-processor "shell-local" {
    inline = [
      "echo convert vmx to ${var.vm_name}.box...",
      "perl perl-vmx2box.pl output-${var.vm_name} output-${var.vm_name}.box",
      "rm -f output-${var.vm_name}/*",
      "rmdir output-${var.vm_name}"
    ]
  }
}
