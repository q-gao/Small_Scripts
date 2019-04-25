#!/usr/bin/perl
# This script kills all the processes that belong to the same program (e.g. Google chrome)
#
#=================================================================================================

use strict;

if( $#ARGV < 0 ) {
  print "USAGE: KillAllProgramProcesses.pl <program_name>\n";
  exit( -1 );
}

my @aPsLines = `ps -ef | grep \'$ARGV[0]\'`;

my $killCmd = "kill -KILL";
my $fKill = 0;
foreach my $line ( @aPsLines ) {
  if( $line =~ /KillAllProgramProcesses\.pl/ ||  # TODO: use #0 to be more flexible
      $line =~ /\s+grep\s+/
     )
  {
    next;
  }

  if( $line =~ /\w+\s+(\d+)\s+/ ) {
    $killCmd .= " $1";
    $fKill = 1;
  }
}

if( $fKill ) {
  print "$killCmd\n";
  system( $killCmd );
}

