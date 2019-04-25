#!/usr/bin/perl

# ParseWordRecognitionResult.pl <result.xml> <word_truth.xml> 
#                              [ <word_img_dir_relative_to_word_truth_xml> 
#                                [ <cut_point_csv_file> ]
#                              ]
# if <word_img_dir_relative_to_word_truth_xml> is specified, it also create images annotated by 
# result & save them in the following dir's in the current dir's (auto created if they don't exist)
#  - Excellent: all the truth words are recognized
#  - Good     : at least one truth words (but not all) are recognized
#  - Poor     : no truth word(s) recognized

use strict;
use File::Basename;
use XML::Twig;

#my $progDir = dirname($0);
#require "$progDir/com/XmlParser.pl";

if ( $#ARGV < 1 ) {
   print "USAGE: ParseWordRecognitionResult.pl <result.xml> <word_truth.xml>\
                                              [<word_img_dir_relative_to_word_truth_xml>\
                                               [<cut_point_csv_file>] ]\n";
   exit(-1);
}

# init for annotated images
#---------------------------------------------------------------
my ($wordImgDir, $annotatedImgRootDir, $flagAnnotate);
if ( $#ARGV >= 2 ) {
   $flagAnnotate = 1;
   $ARGV[2] =~ s/\/$//;    # remove trailing '/' if there is one
   $wordImgDir = dirname( $ARGV[1] ) . "/$ARGV[2]/";
} else {
   $flagAnnotate = 0;   
   $wordImgDir = "-";
}

my ( $excellentDir, $goodDir, $poorDir );
if( $flagAnnotate ) {
   $annotatedImgRootDir = dirname( $ARGV[0] );
   ( $excellentDir, $goodDir, $poorDir ) = (
      "$annotatedImgRootDir/Excellent/",
      "$annotatedImgRootDir/Good/",
      "$annotatedImgRootDir/Poor/",
   );
   
   if ( !( $wordImgDir eq "-" ) ) {
      if ( !( -e $excellentDir ) )   { system("mkdir $excellentDir"); }
      if ( !( -e $goodDir ) )    { system("mkdir $goodDir"); }
      if ( !( -e $poorDir ) ) { system("mkdir $poorDir"); }
   }   
}

my ( $hasCutPoints);
if ( $#ARGV >= 3 ) { # cut pount csv file is provided
   $hasCutPoints = 1;
} else {
   $hasCutPoints = 0;
}

# Process the data
#---------------------------------------------------------------
my ( %hImg2RecogWords, %hImg2TruthWords, %hImg2Cuts, @imgHasNoTruth );

GenImg2WordsHashFromWordRecognitionXml( \$ARGV[0], \%hImg2RecogWords );
GenImg2WordsHashFromWordRecognitionXml( \$ARGV[1], \%hImg2TruthWords );
if( $hasCutPoints ) {
   GenImg2CutsHash( \$ARGV[3],  \%hImg2Cuts);
}

# Calculate the stats
# precision 
#--------------------------------
my ($nPrecisionNumerator, $nPrecisionDenominator) = (0, 0);
foreach my $testImg ( keys( %hImg2RecogWords ) ) {
#   print "$recogW = ", join('/', @{$hImg2Words{$recogW}} ), "\n";
   if( exists($hImg2TruthWords{$testImg}) ) {
      my @p = CompareTwoWordArray( $hImg2RecogWords{$testImg}, $hImg2TruthWords{$testImg} );
      $nPrecisionNumerator   += $p[0];
      $nPrecisionDenominator += $p[1];             
#      print "$testImg: ", join( ',',
#                              CompareTwoWordArray( $hImg2RecogWords{$testImg},
#                                       $hImg2TruthWords{$testImg} )
#                              ), 
#            "\n";      
   } else {
      push(@imgHasNoTruth, $testImg);
#      print "NO ground truth for $testImg\n";
   }
}

# Recall 
#--------------------------------
my ($nRecallNumerator, $nRecallDenominator) = (0, 0);
my ($imgFullName, $label, $bkgrndColor, $outImgFullName, $raCuts);

if( !$hasCutPoints ) {
   $raCuts = [];
}
foreach my $truthImg ( keys( %hImg2TruthWords ) ) {
   if( exists($hImg2RecogWords{$truthImg}) ) {
      my @r = CompareTwoWordArray( $hImg2TruthWords{$truthImg}, $hImg2RecogWords{$truthImg} );
      
#      print "$truthImg: $r[0]/$r[1]\n";     
      $nRecallNumerator   += $r[0];
      $nRecallDenominator += $r[1]; 
         
      if( $flagAnnotate ) {         
         $imgFullName = $wordImgDir.$truthImg;
         $label = join(' ', @{$hImg2TruthWords{$truthImg}} )." => ".join(' ', @{$hImg2RecogWords{$truthImg}} );
         if( $hasCutPoints && exists( $hImg2Cuts{$truthImg} ) )  {
            $raCuts = $hImg2Cuts{$truthImg}->[0];
            
            if( $#{ $hImg2Cuts{$truthImg} } >= 2 ) { # recognization time/score info available
               $label .= " : Time=(";
                 
               for(my $i = 0; $i <= $#{$hImg2Cuts{$truthImg}->[1]}; $i++ ) { # recognization time
                  if( $i != 0 ) {
                     $label .= ",";
                  }
                  $label .= sprintf( "%.3f", $hImg2Cuts{$truthImg}->[1][$i] );
               }
               $label .= ")ms  Score=(";
               for(my $i = 0; $i <= $#{$hImg2Cuts{$truthImg}->[2]}; $i++ ) { # recognization score
                  if( $i != 0 ) {
                     $label .= ",";
                  }
                  $label .= sprintf( "%.3f", $hImg2Cuts{$truthImg}->[2][$i] );
               }
               $label .= ")";                              
            }           
         }  
                  
         if( $r[0] <= 0 ) {   # poor results
            $outImgFullName = $poorDir.$truthImg;
            $bkgrndColor = "red";         
         } elsif( $r[0] == $r[1] ) { # Excellent
            $outImgFullName = $excellentDir.$truthImg;
            $bkgrndColor = "green";
         } else {  # Good
            $outImgFullName = $goodDir.$truthImg;
            $bkgrndColor = "white";         
         }

         GenAnnotatedImgWithCuts( \$imgFullName, \$label, $bkgrndColor, "black", $raCuts, \$outImgFullName );
            
      }
   } 
}

# print results
#--------------------------------
if( $#imgHasNoTruth > 0 ) {
   print "Image(s) without ground truth:\n".join(' ', @imgHasNoTruth);
   print "\n\n";   
}

print "Precision = $nPrecisionNumerator/$nPrecisionDenominator =";
if( $nPrecisionDenominator != 0) {
   print $nPrecisionNumerator/$nPrecisionDenominator;    
} 
print "\n";

print "    Recall= $nRecallNumerator/$nRecallDenominator =";             
if( $nRecallDenominator != 0) {
   print $nRecallNumerator/$nRecallDenominator;    
} 
print "\n";
#========================================================================
sub GenImg2WordsHashFromWordRecognitionXml    #(\$xmlFile, $rhashImg2Word)

  # XML format:
  #   <tagset> # this is root
  #   	<image>
  #   		<taggedRectangles>
  #   			<taggedRectangle>
  #   				<gt_path>../input/binary_image/415_2.bmp</gt_path>
  #   				<tag>61 to  69</tag>
  #   			</taggedRectangle>
  #   		</taggedRectangles>
  #   	</image>
  # RETURN:
  #  Reference to a hash table each of whose elements
  #    $h{<file_name>} = [<word_1>, [<word_2>, ...]]
  #
{
   my ( $rXmlFile, $rhImg2Words ) = @_;

   my $xmlTree = XML::Twig->new();
   $xmlTree->parsefile( ${$rXmlFile} );  # it will die if the file doesn't exist

   my @aXmlImage = $xmlTree->root->children("image");
   my $t;

   foreach my $xmlImg (@aXmlImage) {
      my @aXmlRectSet = $xmlImg->children("taggedRectangles");

      foreach my $xmlRectSet (@aXmlRectSet) {
         my @aXmlRect = $xmlRectSet->children("taggedRectangle");

         foreach my $xmlRect (@aXmlRect) {
            $t = $xmlRect->first_child("tag")->text();
            $t =~ s/^\s*//; # remove leading space if there is any (trailing space is OK).
                            # this is needed to use split function to get the words in the string
            $rhImg2Words->{ 
                           basename( $xmlRect->first_child("gt_path")->text() )
                          } = [  # convert to lower cases
                                 map {lc} split( /\s+/,  $t) 
                              ];
         }
      }
   }
}

#--------------------------------------------------------------------------
sub CompareTwoWordArray    #(\@aFrom, \@aTo)

  # Return the percentage of the words in @aFrom that have matches in @aTo
{
   my ( $raFrom, $raTo ) = @_;
   
   my $numMatch = 0;
   foreach my $w (@{$raFrom}) {
      foreach my $t (@{$raTo}) {
         if( $w eq $t) {
            $numMatch++;
            last;
         }
      }      
   }
   
   return ($numMatch, $#{$raFrom} + 1);
}

##--------------------------------------------------------------------------
#sub GenAnnotatedImg #(\$inImgName, \$label, $backgroundColor, $labelColor, \$outImgName)
#{
#   my ( $rInImgName, $rLabel, $backgroundColor, $labelColor, $rOutImgName ) =
#     @_;
#
#   my $cmd =
#"convert ${$rInImgName} -background $backgroundColor -fill $labelColor label:\"${$rLabel}\" -gravity Center -append ${$rOutImgName}";
#   print "$cmd\n";
#
#   system($cmd);
#}

#--------------------------------------------------------------------------
sub GenAnnotatedImgWithCuts #(\$inImgName, \$label, $backgroundColor, $labelColor, \@aCutPoints, \$outImgName)
{
   my ( $rInImgName, $rLabel, $backgroundColor, $labelColor, $raCutPoints, $rOutImgName ) =
     @_;

   my $cmd = "convert ${$rInImgName}";

   if( $#{$raCutPoints} >= 0 ) {
      $cmd .= " -fill \"rgba(100%, 0, 0, 0.6)\" -stroke none";
       
      my ($x0, $x1, $y1);
      for( my $r = 0; $r <= $#{$raCutPoints} ; $r++) {
         $x0 = $raCutPoints->[$r] - 1;
         $x1 = $raCutPoints->[$r] + 1;
         #TODO: get the image height from the image
         $y1 = 47;      
         $cmd .= " -draw \"rectangle $x0 0 $x1 $y1\""
      }          
   }
   
   $cmd .= " -background $backgroundColor -fill $labelColor label:\"${$rLabel}\" -gravity Center -append ${$rOutImgName}";
   
   print "$cmd\n";

   system($cmd);
}

#-----------------------------------------------------------------------
sub  GenImg2CutsHash # (\$cutCsvFile, \%hImg2Cuts)
{
   my ( $rCutCsvFile, $rhImg2Cuts) = @_;
   
   my ( $fhCsv);
   
   open $fhCsv, "< $$rCutCsvFile" or die "FAILED to open $$rCutCsvFile\n";
   
   my (@rst, @cutX);
   while( my $line = <$fhCsv> ) {
      chomp($line);
      $line =~ s/\r//g;  # remove "\r"
      @rst = (); @cutX = ();
      if( GetSegRecogResult( \$line, \@rst, \@cutX) ) {
         $rhImg2Cuts->{ $rst[0] }[0] = [ @cutX ];
         if( $#rst >= 3 ) { # NOTE: the recognization time/score may not be available in the csv file
            $rhImg2Cuts->{ $rst[0] }[1] = [ @{$rst[2]} ];   #recognization time
            $rhImg2Cuts->{ $rst[0] }[2] = [ @{$rst[3]} ];   #recognization score        
         }      
      }
   }
}
#-----------------------------------------------------------------------
sub  GetSegRecogResult # (\$line, \@rst, \@cutX)
#DESCRIPTION:
# Read the segmenation & recognion results from the csv file generated by testOCR
# (w/ PRINT_CUT_POINT). An example line in the csv file looks like:
#   bPict0027_3.bmp,51,25,25,51,25,51,"APOLLO " 
#
# ARGUMENTS:
#  - \@rst:  returned results 
#      - $rst[0] = image name; 
#      - $rst[1] = recognized text
#      - $rst[2] = array of recognization_time(in ms) : one element per word
#      - $rst[3] = array of recognization_score       : one element per word
#      - $rst[4] = array of cut_flag(a word is cut or not): one element per word
#
# RETURN:
#     1: the line has cut/recognition info
#     0: otherwise
{
   my ( $rline, $raRst, $raCutX) = @_;

   if( $$rline =~ /(.+),\"(.*)\",?(.*)$/ ) {  # the recognition result could be empty
      # $1: image name + cut points (if there is any)
      # $2: recognition result
      # $3: recognition time, score and flag, if there is any
      $raRst->[1] = $2;
      
      my @rsPair = split(",", $3); # NOTE: it's OK if $3 is empty

      for (my $dii = 0; $dii <= $#rsPair; $dii += 3) {
      	 $raRst->[2]->[$dii/3] = $rsPair[$dii];
      	 $raRst->[3]->[$dii/3] = $rsPair[$dii+1];
      	 $raRst->[4]->[$dii/3] = $rsPair[$dii+2];
      }  
      
      my @elem = split(",", $1);
      if( $#elem >= 0 ) {
         $raRst->[0] = $elem[0]; # image name
         
         my %hx;
         @$raCutX = ();
         for(my $i = 1; $i <= $#elem; $i++ ) { # cut positions
            if( !exists( $hx{ $elem[$i] } ) ) { # remove duplicate cuts
               push( @$raCutX, $elem[$i]);
               $hx{ $elem[$i] } = 1;
            }
         }                  
         return   1;         
      }
   }
   return 0;
}