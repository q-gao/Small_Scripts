#!/usr/bin/perl
# Usage:
#  BatchBinarizeImages.pl <char_img_folder> <output_image_dir> <binarizing_program>
#
# Example:
#   OverlayCharImgOverBackground.pl char/ WhiteBackground_VGA.png char_VGA ./trianglethresh
#
use strict;
use File::Basename;



if($#ARGV < 2) {
 print "BatchBinarizeImages.pl <char_img_folder> <output_image_dir> <binarizing_program>\n";
 exit(-1);
}

our $cmdBinarize = $ARGV[2]; #"./trianglethresh";  # bash script to call ImageMagick

my (@charImgs, $cmd, $outDir);

if($ARGV[1] =~ /.*\/$/) {
  $outDir = $ARGV[1];
} else {
  $outDir = "$ARGV[1]/"; # append / at the end if it doesn't exist
}

@charImgs = `find $ARGV[0] -name "*.jpg"`;
foreach my $cimg (@charImgs)
{
  chomp($cimg);

  my ($ibn);
  $ibn = basename($cimg);

  $cmd = "$cmdBinarize $cimg $outDir$ibn";
  print "$cmd\n";
  system($cmd);
}



