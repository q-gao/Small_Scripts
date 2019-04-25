#!/usr/bin/perl
#
# USAGE:
#   MontageImsInDirs.pl <img_file_name_pattern> <dir_1> [<dir_2> [...]]
#
#    The montage image for <dir_name> will be save as "montage_<dir_name>.jpg"
#
# Example:
#   MontageImsInDirs.pl "*.bmp" 0/ 1/
#   MontageImsInDirs.pl "*.bmp" `ls`
#

if($#ARGV < 1) {
	print "Usage:\n MontageImsInDirs.pl <img_file_name_pattern> <dir_1> [<dir_2> [...]]\n\n";
	print "Example:\n MontageImsInDirs.pl \"*.bmp\" 0/ 1/\n";
	exit(-1);
}

foreach $dir (@ARGV[1 .. $#ARGV]) {
	$dir =~ s/\/$//;  # remove trailing '/' if there is one
	$outImgName = "montage_$dir.jpg";
	$cmd = "montage -frame 1 `ls $dir/$ARGV[0]` $outImgName" ;
	print "$cmd\n";
	system($cmd);
}