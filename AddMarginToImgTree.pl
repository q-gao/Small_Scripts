#!/usr/bin/perl
#
# USAGE:
#   AddMarginToImgTree <orig_img_root_dir> <img_file_name_pattern> <margin_size> <margin_color> <num_color_in_out_image> <new_img_root_dir>
#
#   Example:
#      AddMarginToImgTree Orig/ "*.bmp"  1 black 16 New/
#

use File::Basename;

my $programDir = dirname($0);
require "$programDir/com/utility.pl";
require "$programDir/com/UtilImageMagicK.pl";

if ( $#ARGV < 5 ) {
   print
"Usage:\n  AddMarginToImgTree <orig_img_root_dir> <img_file_name_pattern> <margin_size> <margin_color> <num_color_in_out_image> <new_img_root_dir>\n\n";
   print "Example:\n";
   print "    AddMarginToImgTree Orig/ \"*.bmp\"  1 black 16 New/\n";
   exit(-1);
}

my $inDirDepth = GetDirDepth( $ARGV[0] );
my ( $marginSize, $marginBothSize, $marginColor, $numColors ) =
  ( $ARGV[2], $ARGV[2] + $ARGV[2], $ARGV[3], $ARGV[4]);
my @newRootDir = split( '/', $ARGV[5] );


my @origImgs = `find $ARGV[0] -name \"$ARGV[1]\"`;

my ( $cmd, @resolution, $w, $h );
foreach my $origImg (@origImgs) {
   chomp($origImg);
   my @origdir = split( '/', dirname($origImg) );
   my $imgBaseName = basename($origImg);

   my @newdir = ( @newRootDir, @origdir[ $inDirDepth .. $#origdir ] );

   CreateDirIfNotExist_ArrayFormat( \@newdir );
   if ( GetImageResolution( \$origImg, \@resolution ) ) {
      $w = $resolution[0] + $marginBothSize;
      $h = $resolution[1] + $marginBothSize;
      $cmd =
"convert -size ${w}x$h xc:$marginColor -draw \"image over ${marginSize}x$marginSize 0,0 $origImg\" -colors $numColors "
        . join( '/', @newdir )
        . "/$imgBaseName";

      print "$cmd\n";
      system($cmd);
   }
}

