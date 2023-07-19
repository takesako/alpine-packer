variable "iso_url" {
  type    = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86/alpine-standard-3.18.2-x86.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:4b5d0762629d520422daeaaac55f7a159caee5e93bcab8860b0386ff51bc0e71"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.18.2-x86"
}

variable "guest_os_type_virtualbox" {
  type    = string
  default = "Linux26"
}

variable "guest_os_type_vmware" {
  type    = string
  default = "other5xlinux"
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

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "alpine" {
  vm_name              = "${var.vm_name}"
  communicator         = "ssh"
# cdrom_adapter_type   = "sata"
  disk_size            = "8192"
# disk_adapter_type    = "nvme"
  format               = "ova"
  guest_additions_mode = "disable"
  guest_os_type        = "${var.guest_os_type_virtualbox}"
  headless             = false
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
# keep_registered      = true
  output_directory     = "output-${var.vm_name}"
  shutdown_command     = "/sbin/poweroff"
# skip_export          = true
  ssh_password         = "${var.root_password}"
  ssh_timeout          = "3m"
  ssh_username         = "root"
  usb                  = true
  vboxmanage           = [
	["modifyvm", "{{ .Name }}", "--memory", "256"],
	["modifyvm", "{{ .Name }}", "--vram", "33"],
	["modifyvm", "{{ .Name }}", "--ioapic", "on"],
	["modifyvm", "{{ .Name }}", "--cpus", "2"],
	["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
	["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
	["modifyvm", "{{ .Name }}", "--chipset", "ich9"],
	["modifyvm", "{{ .Name }}", "--nic1", "nat"],
	["modifyvm", "{{ .Name }}", "--nictype1", "virtio"],
	["modifyvm", "{{ .Name }}", "--cableconnected1", "on"],
        ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"],
	["modifyvm", "{{ .Name }}", "--audio-enabled", "off"],
	["modifyvm", "{{ .Name }}", "--audio-in", "off"],
	["modifyvm", "{{ .Name }}", "--audio-out", "off"],
	["modifyvm", "{{ .Name }}", "--audio-controller", "ac97"],
	["modifyvm", "{{ .Name }}", "--vrde", "off"],
	["modifyvm", "{{ .Name }}", "--usbohci", "on"],
	["modifyvm", "{{ .Name }}", "--usbehci", "on"],
	["modifyvm", "{{ .Name }}", "--usbxhci", "on"]
  ]
# boot_key_interval    = "15ms"
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
	cat /mnt/etc/apk/repositories<enter><wait>
	umount /mnt<enter><wait1>
	# /etc/init.d/sshd restart<enter><wait1>
	reboot<enter><wait1>
	EOF
	]
}

build {
  sources = [
    "source.virtualbox-iso.alpine"
  ]
  provisioner "shell" {
    inline = [
      "sed '/PermitRootLogin yes/d' -i /etc/ssh/sshd_config",
      "echo 'vagrant:${var.vagrant_password}' | chpasswd",
      "sed -r 's;#(.*[0-9]/community);\\1;g' -i /etc/apk/repositories",
      "sed -r 's;(.*/edge/main);#\\1;g' -i /etc/apk/repositories",
      "apk update"
    ]
  }
  provisioner "shell" {
    inline = [
      "apk add virtualbox-guest-additions",
      "rc-update add virtualbox-guest-additions",
      "rc-update add local",
      "addgroup vagrant vboxsf"
    ]
  }
  provisioner "shell" {
    scripts = [
      "x-provision.sh",
      "x-vmdiskclean.sh"
    ]
  }
  post-processor "shell-local" {
    inline = [
      "VBoxManage import output-${var.vm_name}/${var.vm_name}.ova",
#     "VBoxManage storageattach ${var.vm_name} --storagectl=\"IDE Controller\" --port=1 --device=0 --type=dvddrive --medium=none",
      "echo execute 'vagrant package'command to making ${var.vm_name}.box",
      "vagrant package --base ${var.vm_name} --output output-${var.vm_name}/${var.vm_name}.box",
      "VBoxManage unregistervm ${var.vm_name} --delete-all"
    ]
  }
}
