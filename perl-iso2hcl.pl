#!/usr/bin/perl
use strict;
use warnings;
use LWP::Protocol::https;
use LWP::UserAgent;
use File::Slurp;

$ENV{"PERL_LWP_SSL_VERIFY_HOSTNAME"} = 0;

my $alpine_prefix = ["alpine-standard", "alpine-virt"];

my $build_arch = { "x86_64" => 1, "aarch64" => 1 };

my $guest_os_type_virtualbox = {
  "x86" => "Linux26",
  "x86_64" => "Linux26_64",
  "armv7" => "not supported",
  "aarch64" => "not supported",
};

my $guest_os_type_vmware = {
  "x86" => "other5xlinux",
  "x86_64" => "other5xlinux-64",
  "armv7" => "not supported",
  "aarch64" => "arm-other5xlinux-64",
};

my $ua = LWP::UserAgent->new();
my $url = "https://www.alpinelinux.org/downloads/";
my $res = $ua->get($url);
if (!$res->is_success) {
  die($res->content);
}
my $downloads_html = $res->content;

for my $prefix (@$alpine_prefix) {
  my @iso_sha256 = $downloads_html =~ /(https:.+?$prefix-[0-9]+.[0-9]+.[0-9]+-\w+\.iso\.sha256)"/g;
  for my $url (@iso_sha256) {
    $url =~ s/&#x2F;/\//g;
    my ($vm_name, $arch) = $url =~ /($prefix-[\w\.]+-(\w+))/;
    if (exists $build_arch->{$arch} && $build_arch->{$arch}) {
      my ($iso_url) = $url =~ /^(.*)\.sha256$/;
      sleep(1);
      my $iso_checksum = $ua->get($url)->content;
      ($iso_checksum) = $iso_checksum =~ /^(\w+)\s/;
      my $filename = "$prefix/$vm_name.pkrvars.hcl";
      my $content =<<EOF;
iso_url = "$iso_url"
iso_checksum = "sha256:$iso_checksum"
vm_name = "$vm_name"
guest_os_type_virtualbox = "$guest_os_type_virtualbox->{$arch}"
guest_os_type_vmware = "$guest_os_type_vmware->{$arch}"
EOF
      print STDERR "$filename: writing...\n--\n$content\n";
      write_file($filename, {binmode => ':raw'}, $content);
    }
  }
}

1;
