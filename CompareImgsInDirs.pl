#!/usr/bin/perl
# Usage:
#  CompareImgsInDirs <image_file_name_pattern> <img_display_resolution> <dir_1> <dir_2> 
#
# Example:
#   CompareImgsInDirs.pl "*.jpg" 120x120 char/ char_BlackWhite/ 
#
use strict;
use File::Basename;
use threads;  # Perl needs to be compiled to support threading. see https://wiki.bc.net/atl-conf/pages/viewpage.action?pageId=20548191
use threads::shared;

my $programDir = dirname($0);
require "$programDir/com/utility.pl";

our $cmdMontage = "montage";  # from ImageMagick
our $cmdDisp = "display";  # from ImageMagick

if($#ARGV < 3) {
 print "<image_file_name_pattern> <img_display_resolution> <dir_1> <dir_2> [<more_dirs>]\n";
 exit(-1);
}

if(!($ARGV[1] =~ /\d+x\d+/)) {
   print "The resolution(2nd argument) is not in the format of <width>x<height>\n";
   exit(-1);
}

my %hashImgNames;

# get image file names
#-------------------------------------------------------
foreach my $dir (@ARGV[2 .. $#ARGV]) {
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
    
    $cmd .= " - | $cmdDisp -"; 
    
    print "\n-------------------------------------------------------------\n$cmd\n------------------------------------------------------\n\n";    
	 my $t = threads->new(\&Thread_ExecCommand, $cmd);

     print "\n";
     my $in = PromptUser("Options: N=Next, Q=Quit ","N");
     my @pids = GetProcessID($cmdDisp);
     foreach (@pids) {
      system("kill -KILL $_ >/dev/null");       
       #open(my $fhKill, "kill -KILL $_");
       
     }
	 
	 #$t->join(); #join cause problem??
     if(uc($in) eq "Q") {
		last;
     }
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

