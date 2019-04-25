#!/usr/bin/perl
# Usage: VectorCommand <cmd> -op1 <operand list 1> [-op2 <operand list 2> [...]]
#
# Examples:
#  - rename *.hs16.idgen to *.idgen
#  VectorCommand.pl mv -op1 *hs16.idgen -op2 `/sreplace.pl '.hs16.idgen' '.idgen' *hs16.idgen`

use strict;

if($#ARGV< 2) {
    print "Usage: VectorCommand <cmd> -op1 <operand list 1> [-op2 <operand list 2> [...]]\n";
    print "        - if only one element follows a -op switch, the element will be repeated to the needed command run times\n";
    exit(-1);
}

# parse the operands
my $curOpIdx = -1; # init it with an invalud operand index (valid one starts with 1)
my @aOpVectors = ();
foreach my $tkn ( @ARGV[1 .. $#ARGV] ) {
    if( $tkn =~ /^-op(\d+)$/ ) {
        $curOpIdx = $1;
        # start a new operand vector
        $aOpVectors[$curOpIdx - 1] = [] ; # operand index starts from 1 vs. the array index starts from 0
    } else {
        push( @{$aOpVectors[$curOpIdx - 1]}, $tkn ); # operand index starts from 1 vs. the array index starts from 0
    }
}

# find the command run times
my $numRunTimes = $#{$aOpVectors[0]};
for (my $i = 1; $i <= $#aOpVectors; $i++ ) {
    if ( $#{$aOpVectors[$i]} > $numRunTimes ) {
        $numRunTimes = $#{$aOpVectors[$i]};
    }
}

for(my $i = 0; $i <= $#aOpVectors; $i++ ) {
    if( $#{$aOpVectors[$i]} != $numRunTimes ) {
        if ($#{$aOpVectors[$i]} == 0) { # repeat operand
            for (my $r = $numRunTimes; $r > 0; $r--) {
                $aOpVectors[$i][$r] = $aOpVectors[$i][0];
            }
        } else {
            print "ERROR: Not all operands have the same elements!\n";
            exit(-3);            
        }
    }
}

# run the command
my $cmd;
for( my $i = 0; $i <= $numRunTimes; $i++ ) {    
    $cmd = "$ARGV[0]";
    for( my $n = 0; $n <= $#aOpVectors; $n++ ) {
        $cmd .= " $aOpVectors[$n][$i]";
    }
    print   $cmd ."\n";
    system( $cmd );
}
