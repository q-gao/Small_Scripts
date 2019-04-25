#!/usr/bin/perl

# Format of XML Truth File for char images:
#===============================================
#<?xml version="1.0" encoding="iso-8859-1"?>
#<imagelist>
#  <image file="char/1/1.jpg" tag="3" />
#</imagelist>

use strict;
use File::Basename;

my @dirs = `ls`;

print "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n";
print "<imagelist>\n";

foreach (@dirs) {
   chomp;
   PrintImageElemInDir($_);
}

print "</imagelist>\n";


#======================================================
sub PrintImageElemInDir #($dir)
{
   my $dir = shift;
   my @aFileNames = `find $dir -name "*.bmp"`;
   
   foreach (@aFileNames) {
      chomp;
      my $bnm = basename($_);
      
      print " <image file=\"$bnm\" tag=\"$dir\" />\n";
   }
}
