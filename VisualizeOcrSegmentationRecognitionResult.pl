#!/usr/bin/perl

#convert binary_image/dpCT0006_3.bmp -fill "rgba(100%, 0, 0,0.6)" -stroke none -draw "rectangle 326 0 328 47" label:Hello -append t.bmp

use strict;

use File::Basename;
my $progDir = dirname($0);
require "$progDir/com/utility.pl";
require "$progDir/com/UtilImageMagicK.pl";


if( $#ARGV < 2 ) {
   print "USAGE: <prog_name> <result_file> <input_img_folder> <output_img_folder>\n";
   exit(-1);
}

$ARGV[1] =~ s/\///g;   # remove the ending "/" if there is any
$ARGV[2] =~ s/\///g;   # remove the ending "/" if there is any
CreateDirIfNotExist(\$ARGV[2]); 

my ($fhResult, $line, @rst, @cutX, $cmd);
open $fhResult, "<$ARGV[0]" or die "FAILED to open $ARGV[0]\n";

while( $line = <$fhResult> ) {
   chomp($line);
   $line =~ s/\r//g; # remove "\r"
   if( GetSegRecogResult( \$line, \@rst, \@cutX) ) {
#      if( $rst[0] eq "dpCT0006_3.bmp") {
#         print "$rst[0]\t$rst[1]\t", join(" ", @cutX),"\n";                
#      }
      $cmd = "convert \"$ARGV[1]/$rst[0]\"";
      
      if( $#cutX >= 0 ) {
         $cmd .= " -fill \"rgba(100%, 0, 0,0.6)\" -stroke none";
          
         my ($x0, $x1, $y1);
         for( my $r = 0; $r <= $#cutX ; $r++) {
            $x0 = $cutX[$r] - 1;
            $x1 = $cutX[$r] + 1;
            #TODO: get the image height from the image
            $y1 = 47;      
            $cmd .= " -draw \"rectangle $x0 0 $x1 $y1\""
         }          
      }
      
      $cmd .= " -background Orange label:\"$rst[1]\" -append \"$ARGV[2]/";
      if( $#cutX >= 0 ) {
         $cmd .= "Cut_$rst[0]\""
      } else {
         $cmd .= "NoCut_$rst[0]\""         
      }
      print $cmd,"\n";
      system($cmd);       
   }
}
close($fhResult);

#======================================================================================
sub  GetSegRecogResult # (\$line, \@rst, \@cutX)
# ARGUMENTS:
#  - \@rst:  returned results $rst[0] = image name; $rst[1] = recognized text
{
   my ( $rline, $raRst, $raCutX) = @_;

   my ( @elem);
   #Example line:
   #  bPict0027_3.bmp,51,25,25,51,25,51,"APOLLO "  
   if( $$rline =~ /(.+),\"(.*)\"$/ ) {  # the recognition result could be empty
      $raRst->[1] = $2;
      @elem = split(",", $1);
      if( $#elem >= 0 ) {
         $raRst->[0] = $elem[0]; # image name
         
         my %hx;
         @$raCutX = ();
         for(my $i = 1; $i <= $#elem; $i++ ) { # cut positions
            if( !exists( $hx{ $elem[$i] } ) ) { # remove duplicate cuts
               push( @$raCutX, $elem[$i]);
               $hx{ $elem[$i] } = 1;
            }
         }                  
         return   1;         
      }
   }
   return 0;
}