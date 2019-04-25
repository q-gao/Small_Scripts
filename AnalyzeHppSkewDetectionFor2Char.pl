#!/usr/bin/perl
use strict;

# Char Vertical Span Type
#----------------------------------------
#   0:  a char occupies both the top & middle portion, e.g., A, b, d
#   1:  a char occupies only the middle portion, e.g., a, c, e
#   2:  a char occupies only the middle & bottom portion, e.g., p,q
#   3:  all 3 portions, e.g., j, f in fancy font

# Long Vertical Line Type
#----------------------------------------
#   0: no LVL
#   1: left LVL
#   2: mid LVL
#   3: right LVL
#   4: left & right LVLs: only in H, M, N, U

# all captial letters are of type 0: how about Q????
our %hChar2SpatialInfo = (

   # vertical_Span_type, has_long_vertical_line
   'a' => [ 1, 0 ],    #
   'b' => [ 0, 1 ],
   'c' => [ 1, 0 ],
   'd' => [ 0, 3 ],
   'e' => [ 1, 0 ],
   'f' => [ 0, 1 ],
   'g' => [ 2, 3 ],
   'h' => [ 0, 1 ],
   'i' => [ 0, 2 ],    #??? based one w/o dot
   'j' => [ 2, 2 ],    #??? based one w/o dot
   'k' => [ 0, 1 ],
   'l' => [ 0, 2 ],
   'm' => [ 1, 0 ],
   'n' => [ 1, 0 ],
   'o' => [ 1, 0 ],
   'p' => [ 2, 1 ],
   'q' => [ 2, 3 ],
   'r' => [ 1, 0 ],
   's' => [ 1, 0 ],
   't' => [ 0, 2 ],
   'u' => [ 1, 0 ],
   'v' => [ 1, 0 ],
   'w' => [ 1, 0 ],
   'x' => [ 1, 0 ],
   'y' => [ 2, 0 ],
   'z' => [ 1, 0 ]
);

my @failedCharPairTypes = ( [], [], [] );
my ( $charPair, $prob, $cvt, $num, $ii );
while (<>) {
   if (/\['([\w\d]+)',\s*([\d\.]+)\]/) {
      ( $charPair, $prob ) = ( $1, $2 );
      $cvt = CharPairType($charPair);

      #print "$charPair, $prob: ".CharPairType($charPair)."\n";
      push( @{ $failedCharPairTypes[$cvt] }, [ $charPair, $prob ] );
   }
}

for ( $cvt = 0 ; $cvt <= $#failedCharPairTypes ; $cvt++ ) {
   $num = $#{ $failedCharPairTypes[$cvt] } + 1;
   print "CharPairVerticalType = $cvt \tNum = $num\n";
   print "--------------------------------------------------------\n";
   for ( $ii = 0 ; $ii < $num ; $ii++ ) {
      print join('  ', @{$failedCharPairTypes[$cvt][$ii]})."\n";
   }
}

sub CharPairType    #($charPair)
{
   my $charPair = $_[0];

   my $cvt1 = CharVerticalType( substr( $charPair, 0, 1 ) );
   my $cvt2 = CharVerticalType( substr( $charPair, 1, 1 ) );

   return abs( $cvt1 - $cvt2 );
}

sub CharVerticalType    #($char)
{
   my $c = $_[0];

   if ( ord($c) >= ord('A') && ord($c) <= ord('Z') ) {
      return 0;
   }

   #TODO: add checking if $c exists in the table or not
   return $hChar2SpatialInfo{$c}->[0];
}
