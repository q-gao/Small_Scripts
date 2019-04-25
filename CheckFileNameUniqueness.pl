#!/usr/bin/perl

use strict;
use File::Basename;

if($#ARGV< 1) {
   print "Usage: $0 <root_dir> <file_name_pattern>\n";
   exit(-1);
}

my @aFileNames = `find $ARGV[0] -name $ARGV[1]`;
my %hFileInfo;

foreach my $fnm (@aFileNames) {
   chomp($fnm);
   my $bfnm = basename($fnm);
   if(exists($hFileInfo{$bfnm})) {
      $hFileInfo{$bfnm} ++;
      print "Occurances of $bfnm: $hFileInfo{$bfnm} - $fnm\n";
   } else {
      $hFileInfo{$bfnm} = 1;
   }
} 