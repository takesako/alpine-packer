#!/usr/bin/perl
use strict;
use warnings;
use LWP::Protocol::https;
use LWP::UserAgent;
use File::Slurp;
use File::Path qw(make_path);

$ENV{"PERL_LWP_SSL_VERIFY_HOSTNAME"} = 0;

my $version = shift @ARGV or die "Usage: $0 v3.24\n";

if ($version !~ /^v\d+\.\d+$/) {
  die "version must be like v3.24\n";
}

my $alpine_prefix = ["alpine-standard", "alpine-virt"];

my $build_arch = {
  "x86_64"  => 1,
  "aarch64" => 1,
};

my $guest_os_type_virtualbox = {
  "x86"     => "Linux26",
  "x86_64"  => "Linux26_64",
  "armv7"   => "not supported",
  "aarch64" => "not supported",
};

my $guest_os_type_vmware = {
  "x86"     => "other5xlinux",
  "x86_64"  => "other5xlinux-64",
  "armv7"   => "not supported",
  "aarch64" => "arm-other5xlinux-64",
};

my $ua = LWP::UserAgent->new();
$ua->agent("perl-iso2hcl/1.0");

for my $prefix (@$alpine_prefix) {
  make_path($prefix) unless -d $prefix;

  for my $arch (sort keys %$build_arch) {
    next unless $build_arch->{$arch};

    my $base_url = "https://dl-cdn.alpinelinux.org/alpine/$version/releases/$arch/";

    my $res = $ua->get($base_url);
    if (!$res->is_success) {
      warn "$base_url: " . $res->status_line . "\n";
      next;
    }

    my $html = $res->content;

    my @sha256_files = $html =~ /href="($prefix-\d+\.\d+\.\d+-$arch\.iso\.sha256)"/g;

    # Use only the latest patch version
    @sha256_files = sort {
      my ($a_patch) = $a =~ /-\d+\.\d+\.(\d+)-/;
      my ($b_patch) = $b =~ /-\d+\.\d+\.(\d+)-/;
      $b_patch <=> $a_patch;
    } @sha256_files;
    @sha256_files = $sha256_files[0] ? ($sha256_files[0]) : ();

    for my $sha256_file (@sha256_files) {
      my $sha256_url = $base_url . $sha256_file;
      my $iso_url = $sha256_url;
      $iso_url =~ s/\.sha256$//;

      my ($vm_name) = $sha256_file =~ /^(.+)\.iso\.sha256$/;

      sleep(1);

      my $sha_res = $ua->get($sha256_url);
      if (!$sha_res->is_success) {
        die "$sha256_url: " . $sha_res->status_line . "\n";
      }

      my $iso_checksum = $sha_res->content;
      ($iso_checksum) = $iso_checksum =~ /^([0-9a-fA-F]+)\s/;

      if (!$iso_checksum) {
        die "could not parse checksum: $sha256_url\n";
      }

      my $filename = "$prefix/$vm_name.pkrvars.hcl";

      my $content = <<"EOF";
iso_url = "$iso_url"
iso_checksum = "sha256:$iso_checksum"
vm_name = "$vm_name"
guest_os_type_virtualbox = "$guest_os_type_virtualbox->{$arch}"
guest_os_type_vmware = "$guest_os_type_vmware->{$arch}"
EOF

      print STDERR "$filename: writing...\n--\n$content\n";
      write_file($filename, { binmode => ':raw' }, $content);
    }
  }
}

1;
