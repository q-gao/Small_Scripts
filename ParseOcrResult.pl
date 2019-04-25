#!/usr/bin/perl

# ParseOcrResult.pl <result.xml> <char.xml> <accurancy_stat_file> <candidate_cost_csv_file> [char_img_dir_relative_to_char.xml]

# <accurancy_stat_file>:
#------------------------------------------------------
# <letter>, <num_recognized_images>, <num_images>, <accuracy_prob>
#
# candidate_cost_csv_file (one line per char image):
#------------------------------------------------------
#<letter>, <image_name>, <cost_of_letter>, <cost_of_candidate_1> [<cost_of_candidate_2> ...]
#           -1 if <letter> is not recognized (one of the candidate)
#
use strict;
use File::Basename;

my $progDir = dirname($0);
require "$progDir/com/XmlParser.pl";

if ( $#ARGV < 3 ) {
   print
"USAGE:\n ParseOcrResult.pl <result.xml> <char.xml> <char_accurancy_file> <candidate_cost_file> [char_img_dir_relative_to_char.xml]\n";
   exit(-1);
}

my ( $origCharImgDir, $annotatedImgRootDir );
if ( $#ARGV >= 4 )
{ # also create images annotated by candidates & save them in "Recognized", 'Semirecognized' and "Unrecognized" dirs
   $ARGV[4] =~ s/\/$//;    # remove trailing '/' if there is one
   $origCharImgDir = dirname( $ARGV[1] ) . "/$ARGV[4]";
}
else {
   $origCharImgDir = "-";
}
$annotatedImgRootDir = dirname( $ARGV[0] );

my $rhImg2Char = GenHashFromCharXml( \$ARGV[1] );

# Each element in %{$rhImg2Result}
#    $rhImg2Result->{imageName} = [[<truthChar>,<cost>],
#                                  [<candidate_1, cost_1>],
#                                  [<candidate_2, cost_2>] ...]]
my $rhImg2Result = GenHashFromOcrXmlResult( \$ARGV[0], $rhImg2Char );

##print out results for verification
#foreach my $imgName ( keys( %{$rhImg2Result} ) ) {
#   print "$imgName ";
#   foreach my $raPair (@{$rhImg2Result->{$imgName}}) {
#      print "($raPair->[0],$raPair->[1]) "
#   }
#   print "\n";
#}

my $rhChar2Stat =
  GetOcrAccuracyStat( $rhImg2Result, \$annotatedImgRootDir, \$origCharImgDir );
SaveOcrAccuracyStatToFile( $rhChar2Stat, \$ARGV[2] );

SaveOcrCandidateCostToFile( $rhImg2Result, \$ARGV[3] );

#========================================================================
sub SaveOcrAccuracyStatToFile    #($rhChar2Stat, \$fileName)
{
   my ( $rhChar2Stat, $rFileName ) = @_;

   my ( $fh, $prob );
   open $fh, ">${$rFileName}" or die $!;

   #Save the results
   foreach my $c ( sort { $a cmp $b } keys( %{$rhChar2Stat} ) ) {
      if ( $rhChar2Stat->{$c}->[1] > 0 ) {
         $prob = $rhChar2Stat->{$c}->[0] / $rhChar2Stat->{$c}->[1];
      }
      else {
         $prob = 0;
      }

      print $fh "$c,$rhChar2Stat->{$c}->[0],$rhChar2Stat->{$c}->[1],$prob\n";
   }
   close $fh;
}

#========================================================================
sub SaveOcrCandidateCostToFile    #($rhImg2Result, \$fileName)
{
   my ( $rhImg2Result, $rFileName ) = @_;

   my ( $fh, $imgName, $line, $ii );
   open $fh, ">${$rFileName}" or die $!;

   #    $rhImg2Result->{$imageName} = [[<truthChar>,<cost>],
   #                                  [<candidate_1, cost_1>],
   #                                  [<candidate_2, cost_2>] ...]]
   foreach $imgName ( keys( %{$rhImg2Result} ) ) {
      $line =
"$rhImg2Result->{$imgName}[0][0],$imgName,$rhImg2Result->{$imgName}[0][1]";
      for ( $ii = 1 ; $ii <= $#{ $rhImg2Result->{$imgName} } ; $ii++ ) {
         $line .= ",$rhImg2Result->{$imgName}[$ii][1]";
      }
      print $fh "$line\n";
   }

   close $fh;
}

#========================================================================
sub GenAnnotatedImg #(\$inImgName, \$label, $backgroundColor, $labelColor, \$outImgName)
{
   my ( $rInImgName, $rLabel, $backgroundColor, $labelColor, $rOutImgName ) =
     @_;

   my $cmd =
"convert ${$rInImgName} -background $backgroundColor -fill $labelColor label:\"${$rLabel}\" -gravity Center -append ${$rOutImgName}";
   print "$cmd\n";

   system($cmd);
}

#========================================================================
sub GetOcrAccuracyStat #($rhImg2Result, \$annotatedImgRootDir, \$origCharImgDir)

#ARGUMENTS:
#   $origCharImgDir: if it is not "-", it will genenrate annotated char images & save them
#                    in $annotatedImgRootDir/Recognized & $annotatedImgRootDir/Unrecognized
#RETURN:
#  a hash table mapping a char to [<num_recognized_images>, <num_images>]
{
   my ( $rhImg2Result, $rAnnotatedImgRootDir, $rOrigCharImgDir ) = @_;

   my ( $excellentDir, $goodDir, $fairDir, $poorDir ) = (
      "${$rAnnotatedImgRootDir}/Excellent",
      "${$rAnnotatedImgRootDir}/Good",
      "${$rAnnotatedImgRootDir}/Fair",
      "${$rAnnotatedImgRootDir}/Poor",
   );

   my $flagAnnotate;
   if ( !( $$rOrigCharImgDir eq "-" ) ) {
      if ( !( -e $excellentDir ) )   { system("mkdir $excellentDir"); }
      if ( !( -e $goodDir ) )    { system("mkdir $goodDir"); }
      if ( !( -e $fairDir ) )    { system("mkdir $fairDir"); }
      if ( !( -e $poorDir ) ) { system("mkdir $poorDir"); }

      $flagAnnotate = 1;
   }
   else {
      $flagAnnotate = 0;
   }

   my $rhChar2Stat = {};

   my ( $charTruth, $charTop, $inImgName, $outImgName, $label, $raCand, $raTopCand );
   foreach my $f ( keys( %{$rhImg2Result} ) ) {
      if ( $#{ $rhImg2Result->{$f} } >= 1 ) {
  #TODO: handle cases where there are multiple top candidates with the same cost
         $charTruth =
           lc( $rhImg2Result->{$f}->[0]->[0] );    ##### Case insensitive
         $charTop = lc( $rhImg2Result->{$f}->[1]->[0] );  ##### Case insensitive

         $rhChar2Stat->{$charTruth}->[1]++;               # numer of samples

         $raTopCand = GetTopOcrCandidates( $rhImg2Result->{$f} );
         if ( IsOneOfStrings( $charTruth, $raTopCand ) ) { # one of the top candiates
            my $numTopCand = $#{$raTopCand} + 1;
            if ( $numTopCand <= 1 ) { # only one top candidate
               $rhChar2Stat->{$charTruth}->[0]++;

               if ($flagAnnotate) {
                  $inImgName = "${$rOrigCharImgDir}/$f";
                  $label = "$charTruth:" . GenCandidateCostString( $rhImg2Result->{$f} );
                  $outImgName = "$excellentDir/${charTruth}_$f.jpg";
                  GenAnnotatedImg( \$inImgName, \$label, "green", "black",
                     \$outImgName );
               }
            }
            else {
               $rhChar2Stat->{$charTruth}->[0] += ( 1.0 / $numTopCand );

               if ($flagAnnotate) {
                  $inImgName = "${$rOrigCharImgDir}/$f";
                  $label = "$charTruth:" . GenCandidateCostString( $rhImg2Result->{$f} );
                  $outImgName = "$goodDir/${charTruth}_$f.jpg";
                  GenAnnotatedImg( \$inImgName, \$label, "white", "black",
                     \$outImgName );
               }
            }
         }
         else {    # Not the top candidate
            $raCand = GetAllOcrCandidates( $rhImg2Result->{$f} );
            if ( IsOneOfStrings( $charTruth, $raCand ) ) {  # one of the non-top candidates
               if ($flagAnnotate) {
                  $inImgName = "${$rOrigCharImgDir}/$f";
                  $label = "$charTruth:" . GenCandidateCostString( $rhImg2Result->{$f} );
                  $outImgName = "$fairDir/${charTruth}_$f.jpg";
                  GenAnnotatedImg( \$inImgName, \$label, "yellow", "black",
                     \$outImgName );
               }
            } else { # Not even in the candidate
               if ($flagAnnotate) {
                  $inImgName = "${$rOrigCharImgDir}/$f";
                  $label = "$charTruth:" . GenCandidateCostString( $rhImg2Result->{$f} );
                  $outImgName = "$poorDir/${charTruth}_$f.jpg";
                  GenAnnotatedImg( \$inImgName, \$label, "red", "white",
                     \$outImgName );
               }
            }
         }

         #         #Quick finding: >1 top candidates cases: i & l
         #         if ( $#{$raTopCand} >= 1 ) {
         #            print "$f\'s top candidates: "
         #              . join( " ", @{$raTopCand} )
         #              . "\n";
         #         }

      }
   }

   # make sure all elements are defined
   foreach $charTruth ( keys( %{$rhChar2Stat} ) ) {
      if ( !defined( $rhChar2Stat->{$charTruth}->[0] ) ) {
         $rhChar2Stat->{$charTruth}->[0] = 0;
      }
   }

   return $rhChar2Stat;
}

sub IsOneOfStrings    #($str, $raStr)
{
   my ( $str, $raStr ) = @_;

   foreach my $s ( @{$raStr} ) {
      #if ( $str eq $s ) {
      if ( GetEquivalentChar($str) eq GetEquivalentChar($s) ) {
         return 1;
      }
   }
   return 0;
}

sub GetEquivalentChar #($char)
{
   my ($ch) = @_;

   if( $ch eq '0' || $ch eq 'o' || $ch eq 'O') {
      return 'O';
   }

   if( $ch eq 'I' || $ch eq 'i'  # since all recognition results are converted to lower case
      || $ch eq 'L' || $ch eq 'l'
      || $ch eq '1' ) {
      return 'L';
   }
   return $ch;
}

sub GetTopOcrCandidates    #(\@aOcrResults)

  # ASSUME:
  #   >= candidates
  # RETURN:
  #   array of top candidate arrays
  #
{
   my $raOcrResults = shift;

   my $raTopCand = [ $raOcrResults->[1]->[0] ];
   my $topCost   = $raOcrResults->[1]->[1];

   for ( my $dii = 2 ; $dii <= $#{$raOcrResults} ; $dii++ ) {
      if ( $raOcrResults->[$dii]->[1] == $topCost ) {
         push( @{$raTopCand}, $raOcrResults->[$dii]->[0] );
      }
   }

   return $raTopCand;
}

sub GetAllOcrCandidates    #(\@aOcrResults)

  # ASSUME:
  #   >= candidates
  # RETURN:
  #   array of top candidate arrays
  #
{
   my $raOcrResults = shift;

   my $raCand = [ $raOcrResults->[1]->[0] ];

   for ( my $dii = 2 ; $dii <= $#{$raOcrResults} ; $dii++ ) {
         push( @{$raCand}, $raOcrResults->[$dii]->[0] );
   }

   return $raCand;
}

sub GenCandidateCostString    #(\@aOcrResults)

  # ASSUME:
  #   >= candidates
  # RETURN:
  #   array of top candidate arrays
  #
{
   my $raOcrResults = shift;

   my $str = "";
   for ( my $dii = 1 ; $dii <= $#{$raOcrResults} ; $dii++ ) {
      $str .= " $raOcrResults->[$dii][0]=$raOcrResults->[$dii][1]";
   }

   return $str;
}
