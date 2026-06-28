#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Spec;

my $default_url = 'https://vagrantcloud.com/takesako/boxes/alpine-virt-3.24-aarch64/versions/3.24.1/providers/vmware_desktop/arm64/vagrant.box';
my $default_img = 'qcow2.img';

my $url     = shift @ARGV // $default_url;
my $out_img = shift @ARGV // $default_img;

die "too many arguments\nusage: $0 [vagrant.box URL] [output.img]\n" if @ARGV;

my $tmp = tempdir(CLEANUP => 1);

my $vagrant_box = File::Spec->catfile($tmp, 'vagrant.box');
my $box_dir     = File::Spec->catdir($tmp, 'box');

mkdir $box_dir or die "mkdir $box_dir: $!";

run('curl', '-L', '-o', $vagrant_box, $url);
run('tar', 'xf', $vagrant_box, '-C', $box_dir);

my @vmdk = glob(File::Spec->catfile($box_dir, 'disk.vmdk'));
die "no vmdk found in $box_dir\n" unless @vmdk;
die "multiple vmdk files found: @vmdk\n" if @vmdk > 1;

unlink $out_img if -e $out_img;

run('qemu-img', 'convert', '-p', '-O', 'qcow2', $vmdk[0], $out_img);

print "created: $out_img\n";

sub run {
    print '+ ', join(' ', map { shell_quote($_) } @_), "\n";
    system @_;# == 0 or die "command failed: @_\n";
}

sub shell_quote {
    my ($s) = @_;
    return "''" if $s eq '';
    $s =~ s/'/'\\''/g;
    return "'$s'";
}
