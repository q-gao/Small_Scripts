#!/usr/bin/perl
#
# Generate 2 letter combination images
# 
use strict;

# ASCII:
#  65 -  90: A-Z
#  97 - 122: a-z

Gen2LetterCombinationImages(65,65, 65,65); # AA
# Gen2LetterCombinationImages(65,90, 65,90); # AA
# Gen2LetterCombinationImages(65,90, 97,122); #Aa
# Gen2LetterCombinationImages(97,122, 97,122); #aa

#======================================================
sub Gen2LetterCombinationImages  #($asciiStart1, $asciiEnd1, $asciiStart2, $asciiEnd2)
{
   my ($asciiStart1, $asciiEnd1, $asciiStart2, $asciiEnd2) = @_;

   my ($cmd, $str);
   for(my $a1 = $asciiStart1; $a1 <= $asciiEnd1; $a1 ++ ) {
      for(my $a2 = $asciiStart2; $a2 <= $asciiEnd2; $a2 ++ ) {
         $str = chr($a1).chr($a2);
         #$cmd = "convert -background black -fill white -font Times-New-Roman -pointsize 128 -colors 2 label:$str -filter Point -resize x64 $str.png";
         $cmd = "convert -background black -fill white -font Times-New-Roman -pointsize 128 -colors 2 label:$str $str.png";
         print "$cmd\n";
         system($cmd);
      }
   }
}

