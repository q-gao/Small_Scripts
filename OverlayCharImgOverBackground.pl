#!/usr/bin/perl
# Usage:
#  OverlayCharImgOverBackground.pl <char_img_folder> <background_image_file> <output_image_dir>
#
# Example:
#   OverlayCharImgOverBackground.pl char/ WhiteBackground_VGA.png char_VGA
#
use strict;
our $cmdCompose = "composite";  # from ImageMagick
our $cmdConvert = "convert";  # from ImageMagick

my $programDir = dirname($0);
require "$programDir/com/UtilImageMagicK.pl";

our $qndTmpImgFile = "qndTmpImgFile.jpg"; ######### quick and dirty temporary file

if($#ARGV < 2) {
 print "OverlayCharImgOverBackground.pl <char_img_folder> <background_image_file> <output_image_dir>\n";
 exit(-1);
}

my (@charImgs, $cmd, $outDir);

if($ARGV[2] =~ /.*\/$/) {
  $outDir = $ARGV[2];
} else {
  $outDir = "$ARGV[2]/"; # append / at the end if it doesn't exist
}

my (@bkgrndRes);
if(!GetImageResolution(\$ARGV[1], \@bkgrndRes)) {
  print "ERROR: failed to get the resolution of $ARGV[1]\n";
  exit(-2);
}

@charImgs = `find $ARGV[0] -name "*.jpg"`;
foreach my $cimg (@charImgs)
{
  chomp($cimg);
  if($cimg =~ /([^\/]+$)/) {  # get the base file name
    my ($ibn, @res, $imgf);
    $ibn = $1;

    if(!GetImageResolution(\$cimg, \@res)) {
      print "ERROR: failed to get the resolution of $cimg\n";
      next;
    }
    my $resizePcnt = GetResizeFactor(\@res, \@bkgrndRes);
    if($resizePcnt < 100) {
        $cmd = "$cmdConvert $cimg -resize $resizePcnt% $qndTmpImgFile";
	print "  >> $cmd\n";	
	system($cmd);
	$imgf = $qndTmpImgFile;
    } else {
	$imgf = $cimg;
    }

    $cmd = "$cmdCompose -gravity center $imgf $ARGV[1] $outDir$ibn";
    print "$cmd\n";
    system($cmd);
  }
}


#=============================================================
sub  GetResizeFactor #(\@origRes, \@boundRes)
# INPUT:
#   @origRes: origianl resolution
#   @boundRes: bounding resolution
#
# RETURN:
#   resize factor in percentage (from 0 to 100)
{
  my ($rOrigRes, $rBoundRes) = (shift, shift);

  my ($rszf_0, $rszf_1);

  if($rOrigRes->[0] > $rBoundRes->[0]) {
    $rszf_0 =  int($rBoundRes->[0] / $rOrigRes->[0] * 100);
  } else {
    $rszf_0 = 100;
  }

  if($rOrigRes->[1] > $rBoundRes->[1]) {
    $rszf_1 =  int($rBoundRes->[1] / $rOrigRes->[1] * 100);
  } else {
    $rszf_1 = 100;
  }
  
  if($rszf_0 <= $rszf_1) {
   return $rszf_0;
  }
  return $rszf_1;
}


