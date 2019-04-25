#!/usr/bin/perl
#
# DiffOcrResults.pl <result_dir_1> <result_dir_2> <output_dir>

use strict;
use File::Basename;
our @ResultCat = ("Excellent", "Good", "Fair", "Poor");

if($#ARGV < 2) {
   print "USAGE: DiffOcrResults.pl <result_dir_1> <result_dir_2> <output_dir>\n";
   exit(-1);
}

my (%hImg2Results, $outSubdir, $cmd);

$ARGV[0] =~ s/\/\s*$//;  # remove trailing '/' if there is one
$ARGV[1] =~ s/\/\s*$//;  # remove trailing '/' if there is one
$ARGV[2] =~ s/\/\s*$//;

BuildImg2ResultHash(\$ARGV[1], \%hImg2Results);

if(! -f "$ARGV[2]/Better") { system("mkdir $ARGV[2]/Better");}
if(! -f "$ARGV[2]/Equal") { system("mkdir $ARGV[2]/Equal");}
if(! -f "$ARGV[2]/Worse") { system("mkdir $ARGV[2]/Worse");}

for(my $catIdx = 0; $catIdx <= $#ResultCat; $catIdx++) {  
   my @aImgFileNames = `ls $ARGV[0]/$ResultCat[$catIdx]/*.jpg`;  
   foreach my $f (@aImgFileNames) {
      chomp($f);
      my ($char, $origFnm) = GetOrigImgName(\$f);
      
      if( !exists( $hImg2Results{$origFnm} ) ) { next;}
      
      if($catIdx < $hImg2Results{$origFnm}[0]) {  # Better
         $outSubdir = "Better"
      } elsif($catIdx > $hImg2Results{$origFnm}[0]) { # Worse
         $outSubdir = "Worse"
      } else {
         $outSubdir = "Equal"         
      }
      $cmd = "montage -frame 1 $f $hImg2Results{$origFnm}[1] $ARGV[2]/$outSubdir/${char}_$origFnm.jpg";
      print "$cmd\n"; 
      system($cmd);
   }    
} 

#remove trailing '/' if there is one

#======================================================
sub BuildImg2ResultHash #(\$dirName, \%hImg2Results)
{
   my ($rDirName, $rhImg2Results) = @_;
   
   for(my $catIdx = 0; $catIdx <= $#ResultCat; $catIdx++) {
      
      my @aImgFileNames = `ls $$rDirName/$ResultCat[$catIdx]/*.jpg`;  
      foreach my $f (@aImgFileNames) {
         chomp($f);
         my ($char, $origFnm) = GetOrigImgName(\$f);
         $rhImg2Results->{$origFnm} = [$catIdx, $f, $char];
      }    
   } 
}

sub GetOrigImgName #(\$imgFileName)
{
   if(${$_[0]} =~ /.+\/(.)_(.+\.bmp)\.jpg$/) {
      return ($1, $2);
   }
}