#!/usr/bin/perl
#
# USAGE:
#   ConvertImgTree <orig_img_root_dir> <img_file_name_pattern> <ImageMagicK_command> <new_img_root_dir>
#
#   Example:
#      ConvertImgTree Orig/ "*.bmp"  "-filter Point -resize x48 -colors 16 -negate" New/ 
#       uses nearest-neighbor (-filter Point) to resize all BMP images under Orig/
#       to height 48 (preserve the original width),  negate them and save the result in dir New/. 
#       the original directory tree structure is preserved
#


use File::Basename;

my $programDir = dirname($0);
require "$programDir/com/utility.pl";

if($#ARGV < 3) {
   print "Usage:\n  ConvertImgTree <orig_img_root_dir> <img_file_name_pattern> <ImageMagicK_command> <new_img_root_dir>\n\n";
   print "Example:\n";
   print "  ConvertImgTree Orig/ \"*.bmp\"  \"-filter Point -resize x48 -colors 16 -negate\" New/\n";
   print " resize all BMP images under Orig/ to height 48 (preserve the original width),\n";
   print " negate them and save the result in dir New/. The original directory tree structure is preserved\n";
   exit(-1);   
}

my $inDirDepth = GetDirDepth($ARGV[0]);
my @newRootDir = split('/', $ARGV[3]);

my @origImgs = `find $ARGV[0] -name \"$ARGV[1]\"`;

foreach my $origImg (@origImgs) {
   chomp($origImg);
   my @origdir = split('/', dirname($origImg));
   my $imgBaseName = basename($origImg); 
   
   my @newdir = (@newRootDir, @origdir[$inDirDepth .. $#origdir]);
   
   CreateDirIfNotExist_ArrayFormat(\@newdir);
   my $cmd = "convert $origImg $ARGV[2] ".join('/', @newdir)."/$imgBaseName";   
   #my $cmd = "convert $origImg $ARGV[2] jpg:".join('/', @newdir)."/$imgBaseName.bmp";
   print "$cmd\n";
   system($cmd);
}

