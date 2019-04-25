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
sub PrintImageElemInDir    #($dir)
{
   my $dir        = shift;
   my @aFileNames = `find $dir -name "*.png"`;

   my $char = chars74K_ImgDirName2Char( $dir );
   if($char ne ' ') {
      foreach (@aFileNames) {
         chomp;
         my $bnm = basename($_);
         print " <image file=\"$bnm\" tag=\"$char\" />\n";         
      }      
   }
}

sub chars74K_ImgDirName2Char                                 #($dir)

  #RETURN:
  #  0-9 A-Z a-z:
  #  ' ': if the dir name is not correct
  # Digits:
  #   Sample001:  '0' = 48
  #     ...
  #   Sample010:  '9'
  #
  # Letters
  #   Sample011   'A' = 65
  #
  #   Sample037   'a' = 97
  #
{
   my ($dirName) = shift;

   if ( $dirName =~ /Sample0*(\d+)/ ) {
      my $num = $1;
      if ( $num <= 10 ) {
         return chr( $num + 47 );
      } elsif ( $num < 37 ) {
         return chr( $num + 54 );         
      }
      
      return chr( $num + 60 );
   }
   return ' ';
}
