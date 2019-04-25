#!/usr/bin/perl
#
use strict;
use File::Basename;

my $programDir = dirname($0);
require "$programDir/com/UtilImageMagicK.pl";

if ( $#ARGV < 1 ) {
   print "Usage: GetImgsResolution.pl <img_root_dir> <img_file_name_pattern>\n";
   exit(-1);
}

my @aImgs = `find $ARGV[0] -name $ARGV[1]`;

my @res;
foreach my $img (@aImgs) {
   if ( !GetImageResolution( \$img, \@res ) ) {
      print "ERROR: failed to get the resolution of $img\n";
      exit(-2);
   }
   print "$res[0],$res[1]\n";
}
