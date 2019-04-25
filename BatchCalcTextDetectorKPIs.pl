#!/usr/bin/perl
#
# Usage:
#  BatchCalcTextDetectorKPIs.pl <truth_segmentation_XML_file> <detect_segmentation_XML_file> <img_out_dir> [result_csv_file]
#
use strict;
use XML::Twig;
use File::Basename;

my $programDir = dirname($0);
require "$programDir/com/utility.pl";

#-----------------------------------------------------------------------
# parse arguments
if ( $#ARGV < 2 ) {
   PrintUsage();
   exit(-1);
}

our ( $truthRootDir, $truthSegXmlBaseName );
$truthRootDir        = dirname( $ARGV[0] );
$truthSegXmlBaseName = basename( $ARGV[0] );

our ( $detectRootDir, $detectSegXmlBaseName );
$detectRootDir        = dirname( $ARGV[1] );
$detectSegXmlBaseName = basename( $ARGV[1] );

our $outDir = $ARGV[2];
$outDir =~ s/\/$//;    # remove trailing '/' if there is any

our ( $fhResultCsv, $fResultToStdout );

if ( $#ARGV >= 3 ) {
   open $fhResultCsv, ">$ARGV[3]" or die $!;
   $fResultToStdout = 0;
}
else {
   open $fhResultCsv, ">-" or die $!; # write to STDOUT
   $fResultToStdout = 1;
}

#-----------------------------------------------------------------------
# process the XML file
my $truthSegXml = XML::Twig->new();
$truthSegXml->parsefile( $ARGV[0] );    # it will die if the file doesn't exist

my $detectSegXml = XML::Twig->new();
$detectSegXml->parsefile( $ARGV[1] );    # it will die if the file doesn't exist

my ( %hTruthImgElem, %hDetectImgElem, $p, $r, $f );

BuildHashForImgXmlFromSegXml( $truthSegXml,  \%hTruthImgElem );
BuildHashForImgXmlFromSegXml( $detectSegXml, \%hDetectImgElem );

foreach my $imgBaseName ( sort { $a cmp $b } keys(%hDetectImgElem) ) {

   #foreach my $imgBaseName ( keys(%hDetectImgElem) ) {
   if ( exists( $hTruthImgElem{$imgBaseName} ) ) {
      my ( @aoaTruthBoxes, @aoaDetectBoxes );
      my $tIelem = $hTruthImgElem{$imgBaseName};
      GetTextBoxesFromImgXml( $tIelem,                       \@aoaTruthBoxes );
      GetTextBoxesFromImgXml( $hDetectImgElem{$imgBaseName}, \@aoaDetectBoxes );

      # calculate the KPI's
      $p = GetDetectPrecision( \@aoaTruthBoxes, \@aoaDetectBoxes );
      $r = GetDetectRecall( \@aoaTruthBoxes, \@aoaDetectBoxes );
      $f = GetDetectF( $p, $r );

      print $fhResultCsv "$imgBaseName,$p,$r,$f\n";

      # visualize the results and save it
      my $cmd =
          "convert $truthRootDir/"
        . $tIelem->first_child("imageName")->text()
        . " -fill \"graya( 50%, 0.5)\" -stroke white";

      AppendDrawCommand( \$cmd, \@aoaTruthBoxes );
      $cmd .= " -fill \"rgba( 100%, 0%, 0%, 0.5)\" -stroke black";
      AppendDrawCommand( \$cmd, \@aoaDetectBoxes );

      $cmd .= " $outDir/$imgBaseName";

      if ( !$fResultToStdout ) {
         print "$cmd\n";
      }
      #system($cmd);
   }
}

#====================================================================================
sub GetDetectF    #($p, $r)
{
   my ( $p, $r ) = @_;

   if ( $p <= 0 || $r <= 0 ) {
      return 0;
   }

   return 2.0 / ( 1.0 / $p + 1.0 / $r );
}

#====================================================================================
sub GetDetectPrecision    #(\@aoaTruthRects, \@aoaDetectRects)
{
   my ( $raoaTruthRects, $raoaDetectRects ) = @_;
   return GetAverageDetectMatch( $raoaDetectRects, $raoaTruthRects );
}

#====================================================================================
sub GetDetectRecall       #(\@aoaTruthRects, \@aoaDetectRects)
{
   my ( $raoaTruthRects, $raoaDetectRects ) = @_;

   return GetAverageDetectMatch( $raoaTruthRects, $raoaDetectRects );
}

#====================================================================================
sub GetAverageDetectMatch    #(\@aoaRects, \@aoaRefRects)
{
   my ( $raoaRects, $raoaRefRects ) = @_;

   my $nn = $#{$raoaRects} + 1;
   if ( $nn > 0 ) {
      my $p = 0;
      for ( my $ii = 0 ; $ii < $nn ; $ii++ ) {
         $p += GetBestMatchForRectangle( $raoaRects->[$ii], $raoaRefRects );
      }

      return $p / $nn;
   }

   return 0;
}

#====================================================================================
sub GetBestMatchForRectangle    #(\@aRect, \@aoaRects)
{
   my ( $raRrect, $raoaRects ) = @_;

   my ( $bm, $m, $ra );
   $bm = 0;
   foreach $ra ( @{$raoaRects} ) {
      $m = GetMatchOfTwoRectangles( $raRrect, $ra );
      if ( $m > $bm ) { $bm = $m; }
   }

   return $bm;
}

#====================================================================================
sub GetMatchOfTwoRectangles    #(\@rect1, \@rect2)
{
   my ( $raRect1, $raRect2 ) = @_;

   my @raoaRects = ( $raRect1, $raRect2 );
   my ( @aBoundRect, @aIntersectRect );

   CalcBoundingRectangles( \@raoaRects, \@aBoundRect );
   CalcRectanglesIntersection( \@raoaRects, \@aIntersectRect );

   if ( $aIntersectRect[2] >= 0 && $aIntersectRect[3] >= 0 ) {
      return $aIntersectRect[2] *
        $aIntersectRect[3] /
        ( $aBoundRect[2] * $aBoundRect[3] );
   }
   else {
      return 0;
   }
}

#====================================================================================
sub AppendDrawCommand    #($refCmd, \@aoaRects)
{
   my ( $refCmd, $rAoaRects ) = @_;

   foreach my $rar ( @{$rAoaRects} ) {
      my ( $x, $y ) = ( $rar->[0] + $rar->[2] - 1, $rar->[1] + $rar->[3] - 1 );
      ${$refCmd} .= " -draw \"rectangle $rar->[0],$rar->[1] $x,$y\"";
   }
}

#====================================================================================
sub BuildHashForImgXmlFromSegXml    #($segXml, \%hTextBoxesInImgs)

#  <image>
#    <imageName>ryoungt_05.08.2002/aPICT0035.JPG</imageName>
#    <resolution x="1279" y="507" />
#    <taggedRectangles>
#      <taggedRectangle x="513.0" y="89.0" width="154.0" height="75.0" offset="0.0" rotation="0.0" userName="admin">
#        <tag>ARE</tag>
#        <segmentation>
#          <xOff>55.0</xOff>
#          <xOff>106.0</xOff>
#        </segmentation>
#      </taggedRectangle>
#      <taggedRectangle x="310.0" y="91.0" width="156.0" height="72.0" offset="0.0" rotation="0.0" userName="admin">
#		 ...
#      </taggedRectangle>
#    </taggedRectangles>
#  </image>
{
   my ( $segXml, $rhImgsName2Elem ) = @_;
   my @aImgXml = $segXml->root->children("image");

   foreach my $imgXml (@aImgXml) {
      my $imgName     = $imgXml->first_child("imageName")->text();
      my $imgBaseName = basename($imgName);
      $rhImgsName2Elem->{$imgBaseName} = $imgXml;
   }
}

#========================================================================
#
sub GetTextBoxesFromImgXml    #($imgXml, \@aoaRects)
{
   my ( $imgXml, $raoaRects ) = @_;

  #<taggedRectangles>
  #-----------------------------------------------------------------------------
   my $xmlRects = $imgXml->first_child("taggedRectangles");
   GetRectangles( $xmlRects, $raoaRects );

}

#================================================================================
sub GetRectangles             #($xmlRects, \@raoaRects)
{
   my ( $xmlRects, $raoaRects ) = ( shift, shift );

   foreach my $r ( $xmlRects->children("taggedRectangle") ) {
      my $rhAttr = $r->atts();    # ref to hash of the attributes
      push(
         @{$raoaRects},
         [
            $rhAttr->{'x'},     $rhAttr->{'y'},
            $rhAttr->{'width'}, $rhAttr->{'height'}
         ]
      );
   }
}

#================================================================================
sub PrintUsage {
   print
"BatchCalcTextDetectorKPIs.pl <truth_segmentation_XML_file> <detect_segmentation_XML_file> <img_out_dir> [result_csv_file]\n";
}
