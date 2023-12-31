#!/usr/bin/perl
use strict;
use warnings;

use Archive::Tar;
use Cwd;
use File::Slurp;

my $mode = '0644';
my $owner = 'root:root';
my $file;

sub trim_vmx {
  my $vmx = shift;
  $vmx =~ s/^(\Qbios.bootorder\E)\s*=.*$/$1 = "cdrom,hdd"/gmi;
  $vmx =~ s/^(\Qsata0:0.startconnected\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/^(\Qsata0:0.filename\E)\s*=.*$/$1 = "auto detect"/gmi;
  $vmx =~ s/^(\Qsata0:0.devicetype\E)\s*=.*$/$1 = "cdrom-raw"/gmi;
  $vmx =~ s/^(\Qremotedisplay.vnc.enabled\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/^(\QRemoteDisplay.vnc.\E).*$//gmi;
  $vmx =~ s/^(\Qethernet0.generatedAddress\E).*$//gmi;
  $vmx =~ s/^(\Qusb.present\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/^(\Qehci.present\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/^(\Qusb_xhci.present\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/^usb:[0-9]+\..*$//gmi;
  $vmx =~ s/^ehci:[0-9]+\..*$//gmi;
  $vmx =~ s/^usb_xhci:[0-9]+\..*$//gmi;
  $vmx =~ s/^(\Qusb.vbluetooth.startconnected\E)\s*=.*$/$1 = "FALSE"/gmi;
  $vmx =~ s/\n\n+/\n/sg;
  $vmx;
}

my $arg = $ARGV[0];
   $arg =~ s#[\\/].*$##;
my $arg_box = "$arg.box";
   $arg_box = $ARGV[1] if (defined $ARGV[1]);

my $cwd = Cwd::getcwd();
print STDERR "CHDIR: $arg\n";
chdir($arg) or die("$arg: $!");

my $tar = Archive::Tar->new();

foreach $file (glob("*")) {
  print STDERR "$file...\n";
  if ($file =~ /\.vmx$/) {
    my $vmx = File::Slurp::read_file($file);
    $tar->add_data($file, trim_vmx($vmx));
  }
  elsif ($file =~ /\.(nvram|vmsd|vmxf|vmdk)$/) {
    $tar->add_files($file);
  }
  else { # skip *.plist *.scoreboard vmware.log
    next;
  }
  $tar->chmod($file, $mode);
  $tar->chown($file, $owner);
}

$tar->add_data($file = 'metadata.json', '{"provider": "vmware_fusion"}');
$tar->chmod($file, $mode);
$tar->chown($file, $owner);
$tar->add_data($file = 'Vagrantfile', '');
$tar->chmod($file, $mode);
$tar->chown($file, $owner);

print STDERR "OUTPUT: $arg_box\n";
chdir($cwd) or die("$cwd: $!");
$tar->write($arg_box, COMPRESS_GZIP);

1;
