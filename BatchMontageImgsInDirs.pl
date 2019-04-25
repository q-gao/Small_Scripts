#!/usr/bin/perl
# Usage:
#  BatchMontageImgsInDirs <image_file_name_pattern> <img_display_resolution> <out_dir> <dir_1> <dir_2> [<more dirs>] 
#
# Example:
#   BatchMontageImgsInDirs.pl "*.jpg" 120x120 montage_char char/ char_BlackWhite/ 
#
use strict;
use File::Basename;

our $cmdMontage = "montage";  # from ImageMagick
our $cmdDisp = "display";  # from ImageMagick

if($#ARGV < 4) {
 print "Usage: BatchMontageImgsInDirs <image_file_name_pattern> <img_display_resolution> <out_dir> <dir_1> <dir_2> [<more_dirs>]\n";
 exit(-1);
}

if(!($ARGV[1] =~ /\d+x\d+/)) {
   print "The resolution(2nd argument) is not in the format of <width>x<height>\n";
   exit(-1);
}

my $outDir = $ARGV[2];
$outDir =~ s/\/$//; # remove trailing '/' if there is one

my %hashImgNames;

# get image file names
#-------------------------------------------------------
foreach my $dir (@ARGV[3 .. $#ARGV]) {
	UpdateImageNameHash(\%hashImgNames, $dir, $ARGV[0]);	
}
#foreach (keys(%hashImgNames)) {
#  print "$_: (".join(",", @{$hashImgNames{$_}}).")\n";
#}

# get image file names
#-------------------------------------------------------
foreach my $baseName (keys(%hashImgNames)) {
  my $cmd;
  if($#{$hashImgNames{$baseName}} >= 1) {
  	# labelled by file name
    #$cmd = "$cmdMontage -label '%f' -geometry 360x360\\>+2+2 $hashImgNames{$baseName}->[0] $hashImgNames{$baseName}->[1] - | $cmdDisp -";
  	# labelled by dir name
    $cmd = "$cmdMontage -frame 1 -geometry $ARGV[1]\\>+2";
    foreach my $imgName (@{$hashImgNames{$baseName}}) {
    	my $dirName = dirname($imgName);
		$cmd .= " -label $dirName $imgName";    	
    } 
    
    $cmd .= " $outDir/$baseName"; 
    
    print "$cmd\n";
    system($cmd);    
  }
}

#========================================================================
sub UpdateImageNameHash #(\%hashImgNames, $dir, $file_name_pattern)
{
  my ($rhImgNames, $dir, $fnp) = @_;

  my @Imgs = `find $dir -name "$fnp"`;
  foreach my $n (@Imgs) {
     chomp($n);
     my $baseName = basename($n);
     push(@{$rhImgNames->{$baseName}}, $n);
  }
}

