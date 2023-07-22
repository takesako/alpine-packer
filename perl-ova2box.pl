#!/usr/bin/perl
use strict;
use warnings;

use Archive::Tar;

sub trim_ovf {
  my $ovf = shift;
  $ovf =~ s#<ExtraData>.*?</ExtraData>\s*##s;
  $ovf =~ s#<DVDImages>.*?</DVDImages>\s*##s;
  $ovf =~ s#<RemoteDisplay>.*?</RemoteDisplay>\s*##s;
  $ovf =~ s#<GuestProperties>.*?</GuestProperties>\s*##s;
  $ovf;
}

my $arg = $ARGV[0];
   $arg =~ s/\.(\w+)?$//;
my $arg_ova = "$arg.ova";
my $arg_box = "$arg.box";
   $arg_box = $ARGV[1] if (defined $ARGV[1]);

my $tar = Archive::Tar->new($arg_ova) or die;
foreach my $file ($tar->list_files()) {
  print STDERR "$file...\n";
  if ($file =~ /\.ovf$/) {
    my $ovf = $tar->get_content($file);
    $tar->remove($file);
    $tar->add_data('box.ovf', trim_ovf($ovf));
  }
}
$tar->add_data('metadata.json', '{"provider": "virtualbox"}');
$tar->add_data('Vagrantfile', '');
$tar->write($arg_box, COMPRESS_GZIP);

1;
