#!/usr/bin/env perl
use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);
use Archive::Tar;

my $default_url = 'https://vagrantcloud.com/takesako/boxes/alpine-virt-3.24-aarch64/versions/3.24.1/providers/vmware_desktop/arm64/vagrant.box';
my $default_img = 'qcow2.img';

my $url     = shift @ARGV // $default_url;
my $out_img = shift @ARGV // $default_img;

die "too many arguments\nusage: $0 [vagrant.box URL] [output.img]\n" if @ARGV;

check_qemu_img();

my $tmp = tempdir(CLEANUP => 1);

my $vagrant_box = File::Spec->catfile($tmp, 'vagrant.box');
my $box_dir     = File::Spec->catdir($tmp, 'box');

mkdir $box_dir or die "mkdir $box_dir: $!";

run('curl', '-L', '-o', $vagrant_box, $url);

extract_tar_with_perl($vagrant_box, $box_dir);

my @vmdk = (
    glob(File::Spec->catfile($box_dir, 'disk.vmdk')),
    glob(File::Spec->catfile($box_dir, '*.vmdk')),
);

my %seen;
@vmdk = grep { !$seen{$_}++ } @vmdk;

die "no vmdk found in $box_dir\n" unless @vmdk;
# die "multiple vmdk files found: @vmdk\n" if @vmdk > 1;

unlink $out_img if -e $out_img;

run('qemu-img', 'convert', '-p', '-O', 'qcow2', $vmdk[0], $out_img);

print "created: $out_img\n";

sub check_qemu_img {
    print "+ qemu-img --version\n";
    system('qemu-img', '--version');
    die "qemu-img not found" if $? != 0;
}

sub extract_tar_with_perl {
    my ($tar_file, $dest_dir) = @_;

    my $tar = Archive::Tar->new;
    $tar->read($tar_file) or die "failed to read tar archive: $tar_file\n";

    my $cwd = getcwd();
    chdir $dest_dir or die "chdir $dest_dir: $!";

    $tar->extract()
        or die "failed to extract tar archive: $tar_file\n";

    chdir $cwd or die "chdir $cwd: $!";
}

sub run {
    print '+ ', join(' ', map { shell_quote($_) } @_), "\n";
    system @_;
    die "command failed: @_\n" if $? != 0;
}

sub shell_quote {
    my ($s) = @_;
    return "''" if $s eq '';
    $s =~ s/'/'\\''/g;
    return "'$s'";
}
