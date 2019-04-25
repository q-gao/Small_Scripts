#!/usr/bin/perl
#
# This program indents the flat print-out of the K-mean clustering tree from 
# the CameraKeyboard in such a way that the level of indention is proportional to
# the depth level.
#
# By Qiang Gao, 
#===============================================================================

use strict;

our ( $tabIndent, $numChildren ) = ( "    ", 10 );    # number of children = 10

if ( $#ARGV < 0 ) {
   print
     "USAGE: IndentKMeanTreePrintout.pl <kmean_tree_file> [print_centroid]\n";
   exit(-1);
}

our ( $printCentroid, @aIndentTab );
if ( $#ARGV >= 1 ) {
   $printCentroid = int($ARGV[1]);
}
else {
   $printCentroid = 0;
}

my ( $fh, $rhNode, @stack );

open $fh, "<$ARGV[0]" or die "FAILED to open $ARGV[0]";

my $rootNode = GetNextNode($fh);    # root node
$rootNode->{numChildren} = 0;
$rootNode->{level}       = 0;
$rootNode->{uniqueId}    = "";

#print "Root Node\n";
push( @stack, $rootNode );

while (1) {
   $rhNode = GetNextNode($fh);

   if ( $rhNode->{type} == 0 ) { last; }    # root again

   #ONLY for verification
   #IndentPrintNode( $rhNode, " ", 0 );

   UpdateTreeBasedOnStack( \@stack, $rhNode );

 #   if ( $stack[$#stack]->{numChildren} >=
 #      $numChildren )                            # need to find out its parents
 #   {
 #      do {
 #         pop(@stack);
 #         pop(@aIndentTab);
 #      } while ( $stack[$#stack]->{numChildren} >= $numChildren );
 #   }
 #
 #   # now that found its parent
 #   $stack[$#stack]->{numChildren}++;
 #   $rhNode->{level}    = $#stack + 1;
 #   $rhNode->{uniqueId} = "$stack[$#stack]->{uniqueId}.$rhNode->{id}";
 #
 #   IndentPrintNode( $rhNode, join( "", @aIndentTab ), 0 );
 #   if ( $rhNode->{type} != 2 ) {    # NOT leaf node
 #      $rhNode->{numChildren} = 0;
 #      push( @stack,      $rhNode );
 #      push( @aIndentTab, $tab );      # for its children
 #   }
}
FinalUpdateTreeBasedOnStack( \@stack ); # in case there are still more than 2 nodes left in the stack

close($fh);

@aIndentTab = ();
IndentPrintTree($rootNode);

#========================================================
sub IndentPrintTree    #($rhRoot)
{
   my ($rhRoot) = @_;

   IndentPrintNode( $rhRoot, join( "", @aIndentTab ), $printCentroid );
   push( @aIndentTab, $tabIndent );

   if ( exists( $rhRoot->{children} ) ) {    # Leaf node doesn't have children
      foreach my $rhChild ( @{ $rhRoot->{children} } ) {
         IndentPrintTree($rhChild);
      }
   }
   pop( @aIndentTab );   
}

sub UpdateTreeBasedOnStack                                  #($rStack, $rhNode)
{
   my ( $rStack, $rhNode ) = @_;
   my ( $rhParent, $rhChild );

   # my @aIndentTab;

   if ( $rStack->[ $#{$rStack} ]->{numChildren} >=
      $numChildren )    # need to find out its parents
   {
      do {
         $rhChild = pop(@{$rStack});
         UpdateParentCandidatesInfo( $rStack->[ $#{$rStack} ], $rhChild );

         #         pop(@aIndentTab);
      } while ( $rStack->[ $#{$rStack} ]->{numChildren} >= $numChildren );
   }

   # now that found its parent
   $rhParent = $rStack->[ $#{$rStack} ];

   $rhParent->{numChildren}++;
   push( @{ $rhParent->{children} }, $rhNode );

   $rhNode->{level}    = $#{$rStack} + 1;
   $rhNode->{uniqueId} = "$rhParent->{uniqueId}.$rhNode->{id}";

   #   IndentPrintNode( $rhNode, join( "", @aIndentTab ), 0 );
   if ( $rhNode->{type} != 2 ) {    # NOT leaf node
      $rhNode->{numChildren} = 0;
      push( @{$rStack}, $rhNode );

      #      push( @aIndentTab, $tab );      # for its children
   }
   else {
      UpdateParentCandidatesInfo( $rhParent, $rhNode );
   }
}

sub FinalUpdateTreeBasedOnStack  #($rStack)
{
   my ( $rStack ) = @_;   

   my ($rhChild);
   
   while( $#{$rStack} >= 1 ) {
      $rhChild = pop(@{$rStack});
      UpdateParentCandidatesInfo( $rStack->[ $#{$rStack} ], $rhChild );               
   }  
}

sub UpdateParentCandidatesInfo      #($rhParent, $rhChild)
{
   my ( $rhParent, $rhChild ) = @_;

   foreach my $c ( keys %{ $rhChild->{candidates} } ) {
      $rhParent->{candidates}{$c} += $rhChild->{candidates}{$c};
   }
}

sub GetNextNode                     #($fh)

  #RETURN:
  #  root node: if a root node found or end of file. 1st call return root node
  #  chiold node

  # File Format:
  #--------------------
  #Root node
  #
  #Child Node 0
  #vec[0]=12.645502
  #
  #Child Node 0
  #This is a Leaf node
  #vec[0]=11.655053
  #...
  #vec[31]=-1.741986
  #6 weight=318
  #b weight=5
{
   my ($fh) = @_;

   my ($line);
   my $rhNodeInfo = { type =>
        0 };   # Node type: 0= Root node, 1 = non-leaf child node, 2 = leaf node
   while ( $line = <$fh> ) {
      chomp($line);
      if ( $line =~ /^\s*$/ ) { last; }    # blank line

      if ( $line =~ /Node\s+(\d+)/ ) {
         $rhNodeInfo->{id}   = $1;
         $rhNodeInfo->{type} = 1;
      }
      elsif ( $line =~ /vec\[\d+\]=(-*[\d+\.]+)/ ) {
         push( @{ $rhNodeInfo->{centroid} }, $1 );
      }
      elsif ( $line =~ /([\w\d]+)\s+weight=(\d+)/ ) {

         #push( @{ $rhNodeInfo->{candidates} }, [ $1, $2 ] );
         $rhNodeInfo->{candidates}{$1} = $2;
      }
      elsif ( $line =~ /Leaf/ ) {
         $rhNodeInfo->{type} = 2;
      }
   }

   return $rhNodeInfo;
}

sub IndentPrintNode    #($rhNode, $indent, [$printCentroid])
{
   my ( $rhNode, $indent, $printCentroid ) = @_;

   if ( !defined($printCentroid) ) { $printCentroid = 1; }    # default

   #my $line = "${indent}Node $rhNode->{id} (type $rhNode->{type})";
   my $line = "${indent}L$rhNode->{level} Node $rhNode->{uniqueId}";
   if ( $rhNode->{type} == 2 ) {                              # Leaf Node
      $line .= "*";
   }
   else {
      $line .= " ";
   }
   if ( exists( $rhNode->{candidates} ) ) {
      my ( @c, @w );

      #      # If candidates stored as hash
      if ( $rhNode->{type} == 2 ) {    # Leaf Node
         GetHashKeyValueSortedByVal( $rhNode->{candidates}, \@c, \@w );
      }
      else {
         GetHashKeyValueSortedByKey( $rhNode->{candidates}, \@c, \@w );
      }
      
      my $s = sprintf("%3d", scalar keys %{$rhNode->{candidates}} );
      $line .= "($s): " . join( " ", @c ) . " : " . join( " ", @w );
   } else {
      $line .= ": ";      
   }

   if ( exists( $rhNode->{centroid} ) && $printCentroid ) {
      $line .= " : " . join( ' ', @{ $rhNode->{centroid} } );
   }

   print "$line\n";
}

sub GetHashKeyValueSortedByKey    #($refHash, $refKeys, $refVals)
{
   my ( $refHash, $refKeys, $refVals ) = @_;

   @{$refKeys} = sort { $a cmp $b } keys( %{$refHash} );
   foreach ( @{$refKeys} ) {
      push( @{$refVals}, $refHash->{$_} );
   }
}

sub GetHashKeyValueSortedByVal    #($refHash, $refKeys, $refVals)
{
   my ( $refHash, $refKeys, $refVals ) = @_;

   my ( %h, $v );
   foreach ( keys %{$refHash} ) {
      push( @{ $h{ $refHash->{$_} } }, $_ )
        ;                         # NOTE: multuple keys may have the same value
   }

   foreach my $k ( sort { $b <=> $a } keys(%h) ) {
      foreach $v ( @{ $h{$k} } ) {
         push( @{$refKeys}, $v );
         push( @{$refVals}, $k );
      }
   }
}
