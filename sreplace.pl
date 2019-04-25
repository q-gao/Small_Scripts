#!/usr/bin/perl
# Example:
#   BatchRenameFiles ".txt" ".txt.jdi" *.txt
use strict;

if( $#ARGV < 1 ) {
  print "USAGE: $0 <to_be_replaced_pattern> <replacing_pattern> [<strings to be edited by replacement>]\n";
  exit(-1);
}

if( $#ARGV >= 2 ) {
  foreach my $f ( @ARGV[2..$#ARGV] ) {
    my $newFnm = $f;
    $newFnm =~ s/$ARGV[0]/$ARGV[1]/g;
    print $newFnm, " ";
  }
}else {
  my $ifh = *STDIN;
  while(<$ifh>) { # read from stdin
    chomp;
    my $newFnm = $_;
    $newFnm =~ s/$ARGV[0]/$ARGV[1]/g;
    print $newFnm, " ";
	}
}

