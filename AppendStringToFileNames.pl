#!/usr/bin/perl
# Usage:
#  AppendStringToFilesNames.pl  <appended_string>  <file_names>
use strict;

if( $#ARGV < 1 ) {
    print "Usage: AppendStringToFilesNames.pl  <appended_string>  <file_names>\n";
    exit(-1);
}

my $cmd;
foreach my $f (@ARGV[1 .. $#ARGV]) {
    $cmd = "mv $f $f$ARGV[0]";
    print "$cmd\n";
    system($cmd);
}
