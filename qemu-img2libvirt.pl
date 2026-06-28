#!/usr/bin/env perl
use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Spec;
use Archive::Tar;
use IO::Compress::Gzip qw(gzip $GzipError);

my $arch    = shift @ARGV // 'aarch64'; # or 'x86_64'
my $in_img  = shift @ARGV // 'qcow2.img';
my $out_box = shift @ARGV // 'libvirt.box';

die "too many arguments\nusage: $0 [architecture] [qcow2.img] [libvirt.box]\n" if @ARGV;
die "input image not found: $in_img\n" unless -f $in_img;

my $tmp = tempdir(CLEANUP => 1);

my $metadata = <<"JSON";
{
  "provider": "libvirt",
  "format": "qcow2",
  "architecture": "$arch"
}
JSON

my $tar_path = File::Spec->catfile($tmp, 'libvirt.tar');

my $tar = Archive::Tar->new;

$tar->add_files($in_img);
$tar->rename($in_img, './box.img');

$tar->add_data('./metadata.json', $metadata);
$tar->add_data('./Vagrantfile', '');

$tar->write($tar_path) or die "failed to write tar: $tar_path\n";

unlink $out_box if -e $out_box;

gzip $tar_path => $out_box, -Level => 9
    or die "gzip failed: $GzipError\n";

print "created: $out_box\n";
print "architecture: $arch\n";

1;
