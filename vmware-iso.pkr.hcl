variable "iso_url" {
  type    = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86/alpine-standard-3.18.2-aarch64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:1978520ced2a82abe5b71997620c27e9c66e4612ef4d42cb937a8834f48fea4d"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.18.2-aarch64"
}

variable "guest_os_type_virtualbox" {
  type    = string
  default = "not supported"
}

variable "guest_os_type_vmware" {
  type    = string
  default = "arm-other5xlinux-64"
}

variable "install_dev" {
  type    = string
  default = "/dev/nvme0n1"
}

variable "msys_dev" {
  type    = string
  default = "/dev/nvme0n1p3"
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
  cdrom_adapter_type   = "sata"
  disk_size            = "8192"
  disk_adapter_type    = "nvme"
  format               = "vmx"
# guest_additions_mode = "disable"
  guest_os_type        = "${var.guest_os_type_vmware}"
  headless             = false
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  keep_registered      = true
  output_directory     = "output-${var.vm_name}"
  shutdown_command     = "/sbin/poweroff"
  skip_compaction      = true
# skip_export          = true
  ssh_password         = "${var.root_password}"
  ssh_timeout          = "3m"
  ssh_username         = "root"
  usb                  = true
  vmx_data             = {
	"memsize" = "256"
	"numvcpus" = "2"
	"virtualhw.version" = "19"
	"bios.bootorder" = "hdd,cdrom"
	"bios.hddorder" = "nvme0:0"
	"tools.synctime" = "false"
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
	"ethernet0.virtualdev" = "e1000e"
	"scsi0.present" = "FALSE"
	"nvme0.present" = "TRUE"
	"nvme0:0.filename" = "disk.vmdk"
	"nvme0:0.present" = "TRUE"
	"floppy0.present" = "FALSE"
  }
  vmx_data_post        = {
  }
  vmx_remove_ethernet_interfaces = true
  pause_before_connecting = "15s"
  boot_key_interval    = "15ms"
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
	echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config<enter><wait>
	/etc/init.d/sshd restart<enter><wait1>
	EOF
	]
}

build {
  sources = [
    "source.vmware-iso.alpine"
  ]
  # for M1/M2 Mac VMware Fusion, shutdown vm, dissconnect cdrom, start vm
  provisioner "shell-local" {
    inline = [
      "vmrun stop output-${var.vm_name}/${var.vm_name}.vmx hard",
      "perl -e sleep(5)",
      "perl -e \"print qq(sata0:0.startConnected = \x22FALSE\x22)\" >> output-${var.vm_name}/${var.vm_name}.vmx",
      "vmrun start output-${var.vm_name}/${var.vm_name}.vmx",
    ]
  }
  provisioner "shell" {
    pause_before = "20s"
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
  provisioner "shell-local" {
    inline = [
      "perl perl-vmx2box.pl output-${var.vm_name} output-${var.vm_name}.box"
    ]
  }
}
