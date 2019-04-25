#!/usr/bin/perl
# Example:
#   BatchRenameFiles ".txt" ".txt.jdi" *.txt
use strict;

if( $#ARGV < 2 ) {
  print "USAGE: $0 <to_be_replaced_pattern> <replacing_pattern> <files_to_be_renamed>\n";
  exit(-1);
}

my $fileNum = 0;
foreach my $f ( @ARGV[2..$#ARGV] ) {
  my $newFnm = $f;
  $newFnm =~ s/$ARGV[0]/$ARGV[1]/g;
  my $cmd = "mv $f  $newFnm";
  print $cmd, "\n";
  system($cmd);
  $fileNum ++;
}

print "$fileNum files have been renamed\n";
