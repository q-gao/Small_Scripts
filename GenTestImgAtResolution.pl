#!/usr/bin/perl
#
# Generate test images at the required resolution from ICDAR image database
#
# Usage:
#  GenTestImgAtResolution.pl <segmentation_XML_file> <output_dir> <target_resolution>
#   ARGUMENTS:
#      <target_resolution>: in the format of <width>x<height>
#
use strict;
use XML::Twig
  ; # XML parsing module tutoial @ http://www.xml.com/pub/a/2001/03/21/xmltwig.html
    # XML::Twig method
    #my $ps = $sc->first_child('PrimaryServers');
    #$ps->cut_children;
    #$ps->insert_new_elt("Server")->set_att('Name', "New_1");
    # $elem->set_tag("newTag");
    # $elem->delete(); # remove the element
    # $elem->text(); # value of the element
use File::Basename;

#-----------------------------------------------------------------------
# parse arguments
if ( $#ARGV < 2 ) {
   PrintUsage();
   exit(-1);
}

my $programDir = dirname($0);
require "$programDir/com/utility.pl";

our (
   $inRootDir,      $segXmlBaseName,  $outRootDir,
   $targetImgWidth, $targetImgHeight, $targetImgRatio
);
$inRootDir      = dirname( $ARGV[0] );
$segXmlBaseName = basename( $ARGV[0] );

$outRootDir = $ARGV[1];
$outRootDir =~ s/\/$//;    # remove "/" at the end if there is one

if ( $ARGV[2] =~ /(\d+)x(\d+)/ ) {
   $targetImgWidth  = $1;
   $targetImgHeight = $2;
   $targetImgRatio  = $targetImgWidth / $targetImgHeight;
}

#-----------------------------------------------------------------------
# process the XML file
my $origSegXml = XML::Twig->new(
   KeepSpaces => 'true',    # to preserve the format info
                            #pretty_print => 'indented',
);

#my $origSegXml = XML::Twig->new(KeepSpaces => 'true', # to preserve the format info
#								twig_handlers => {
#        							image => \&ProcXMLImageElem
#									}
#								);

$origSegXml->parsefile( $ARGV[0] );    # it will die if the file doesn't exist

my @origImgs = $origSegXml->root->children("image");

foreach my $img (@origImgs) {
   ProcXMLImageElem($img);
}

#-----------------------------------------------------------------------
#save the XML file for the generated images
my $fhOutSegXml;
open $fhOutSegXml, ">$outRootDir/$segXmlBaseName" or die $!;
$origSegXml->print($fhOutSegXml);
#$origSegXml->flush();
close($fhOutSegXml);

#====================================================================================
sub ProcXMLImageElem    #($img)

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
   my $img = shift;

   #my $img = $_; # convention used by Twig handler

  #<imageName>
  #-----------------------------------------------------------------------------
   my $elemImgName = $img->first_child("imageName");
   my $imgName     = $elemImgName->text();    # set_text()
   my $imgBaseName = basename($imgName);
   $elemImgName->set_text("$imgBaseName");

  #<resolution>
  #-----------------------------------------------------------------------------
   my $res = $img->first_child("resolution")
     ;    # %{$res->atts} is the hash table for the attributes
          #$res->set_att( "x", "640", "y", "480" );
   my ( $imgWidth, $imgHeight ) = ( $res->atts()->{"x"}, $res->atts()->{"y"} );

  #<taggedRectangles>
  #-----------------------------------------------------------------------------
   my $xmlRects = $img->first_child("taggedRectangles");
   my @roi;    # region of interest
   GetBoundingRectForTaggedRect( $xmlRects, \@roi );

   my @cropRegion =
     GetMaxCropRegionWithRoi( $imgWidth, $imgHeight, $targetImgRatio, \@roi );

   my $cmd;

# if ($cropRegion[0] >= 0
#  && $cropRegion[1] >= 0
#  && $cropRegion[2] <= $imgWidth
#  && $cropRegion[3] <= $imgHeight )
# {
#  $cmd =
#"convert -crop $cropRegion[2]x$cropRegion[3]+$cropRegion[0]+$cropRegion[1] -resize $targetImgWidth"
#    . "x$targetImgHeight! "
#    . $imgName->text()
#    . " $outRootDir/$imgBaseName";
#  print "$cmd\n";
#  system("$cmd");
# }

   my ( $canvasWid, $canvasHeight, $imgCanvasX, $imgCanvasY );
   if ( $cropRegion[0] >= 0 ) {
      if ( $cropRegion[1] >= 0 ) {

         # SHOULD: $cropRegion[2] <= $imgWidth && $cropRegion[3] <= $imgHeight
         $cmd =
"convert -crop $cropRegion[2]x$cropRegion[3]+$cropRegion[0]+$cropRegion[1] -resize $targetImgWidth"
           . "x$targetImgHeight! $imgName $outRootDir/$imgBaseName";
      }
      else {    # Expand the image vertically
         $canvasWid    = $imgWidth;
         $canvasHeight = $cropRegion[3];
         $imgCanvasX   = 0;
         $imgCanvasY   = -$cropRegion[1];
         $cmd          = "convert -size $canvasWid"
           . "x$canvasHeight xc:white -draw \"image over $imgCanvasX,$imgCanvasY 0,0 \'$imgName\'\"";
         $cmd .= " -crop $cropRegion[2]x$cropRegion[3]+$cropRegion[0]+0";
         $cmd .= " -resize $targetImgWidth" . "x$targetImgHeight!";
         $cmd .= " $outRootDir/$imgBaseName";

         #$cmd .= "jpg:- | display jpg:-";
      }
   }
   else {    # Expand the image horizontally
      $canvasWid    = $cropRegion[2];
      $canvasHeight = $imgHeight;
      $imgCanvasX   = -$cropRegion[0];
      $imgCanvasY   = 0;
      $cmd          = "convert -size $canvasWid"
        . "x$canvasHeight xc:white -draw \"image over $imgCanvasX,$imgCanvasY 0,0 \'$imgName\'\"";
      $cmd .= " -crop $cropRegion[2]x$cropRegion[3]+0+$cropRegion[1]";
      $cmd .= " -resize $targetImgWidth" . "x$targetImgHeight!";
      $cmd .= " $outRootDir/$imgBaseName";

      #$cmd .= " jpg:- | display jpg:-";
   }
     
   print "$cmd\n";
   system("$cmd");

   AdjustTaggedRectangleElems($xmlRects, -$cropRegion[0], -$cropRegion[1], $targetImgWidth / $cropRegion[2] );

}

#================================================================================
sub GetMaxCropRegionWithRoi    #($width, $height, $targetRatio, \@roi)

  # Get the maximum crop region that contains the ROI
{
   my ( $w, $h, $targetRatio, $raRoi ) = @_;

   my ( $widMargin, $heightMargin ) = ( $w - $raRoi->[2], $h - $raRoi->[3] );

   my ( $mw, $mh, @cropRegion, @madj ); # crop region's width and height margins

   $mw = $targetRatio * ( $raRoi->[3] + $heightMargin ) - $raRoi->[2];

   if ( $mw <= $widMargin ) {
      if ( $mw < 0 )
      {    # crop area's width & height margins = (0, >$heightMargin)
         $mw = 0;
         $mh = $raRoi->[2] / $targetRatio - $raRoi->[3];

         $cropRegion[0] = $raRoi->[0];
         $cropRegion[2] = $raRoi->[2];

         @madj =
           GetAdjustedMargin( $mh, $raRoi->[1], $heightMargin - $raRoi->[1] );
         $cropRegion[1] = $raRoi->[1] - $madj[0];
         $cropRegion[3] = $raRoi->[3] + $madj[0] + $madj[1];
      }
      else
      { #($mw >= 0) { # crop area's width & height margins = ($mw, $heightMargin)
         $cropRegion[1] = 0;
         $cropRegion[3] = $h;

         @madj =
           GetAdjustedMargin_Inner( $mw, $raRoi->[0],
            $widMargin - $raRoi->[0] );
         $cropRegion[0] = $raRoi->[0] - $madj[0];
         $cropRegion[2] = $raRoi->[2] + $madj[0] + $madj[1];
      }
   }
   else {

      # it can be proven that "$mh <= $heightMargin"
      # given $mw = $targetRatio * ($h + $heightMargin) - $w > $widMargin
      $mh = ( $raRoi->[2] + $widMargin ) / $targetRatio - $raRoi->[3];

      if ( $mh < 0 ) {  # crop area's width & height margins = ( >$widMargin, 0)
         $mw = $raRoi->[3] * $targetRatio - $raRoi->[2];
         $mh = 0;

         $cropRegion[1] = $raRoi->[1];
         $cropRegion[3] = $raRoi->[3];

         @madj =
           GetAdjustedMargin( $mw, $raRoi->[0], $widMargin - $raRoi->[0] );
         $cropRegion[0] = $raRoi->[0] - $madj[0];
         $cropRegion[2] = $raRoi->[2] + $madj[0] + $madj[1];
      }
      else {            #: $mh >= 0) { # Again, "$mh <= $heightMargin"
                        # crop area's width & height margins = ($widMargin, $mh)
         $cropRegion[0] = 0;
         $cropRegion[2] = $w;

         @madj =
           GetAdjustedMargin_Inner( $mh, $raRoi->[1],
            $heightMargin - $raRoi->[1] );
         $cropRegion[1] = $raRoi->[1] - $madj[0];
         $cropRegion[3] = $raRoi->[3] + $madj[0] + $madj[1];
      }
   }

   # calculate the crop region
   return @cropRegion;
}

sub GetAdjustedMargin_Inner #($adjustedTotalMargin, $origLeftMargin, $origRightMargin)

#
# RETURN:
#  ($adjustedLeftMargin, $adjustedRightMargin) that satisfy the followings
#    - $adjustedLeftMargin / $adjustedRightMargin ~ $origLeftMargin / $origRightMargin
#    - $adjustedLeftMargin <= $origLeftMargin
#    - $adjustedRightMargin <= $origRightMargin
{
   my ( $adjustedTotalMargin, $origLeftMargin, $origRightMargin ) = @_;

   my ( $adjLeftMargin, $adjRightMargin ) =
     GetAdjustedMargin( $adjustedTotalMargin, $origLeftMargin,
      $origRightMargin );

  #	my ($adjLeftMargin, $adjRightMargin, $origTotalMargin);
  #	$origTotalMargin = $origLeftMargin + $origRightMargin;
  #
  #	if($origTotalMargin <= 0) {
  #		$adjLeftMargin = $adjustedTotalMargin / 2;
  #		$adjRightMargin = $adjustedTotalMargin - $adjLeftMargin;
  #	} else {
  #		$adjLeftMargin = $origLeftMargin / $origTotalMargin * $adjustedTotalMargin;
  #		$adjRightMargin = $adjustedTotalMargin - $adjLeftMargin;
  #	}
  #
  #	# make the adjusted margins integers
  #	$adjLeftMargin = int($adjLeftMargin + 0.5);
  #	$adjRightMargin = int($adjRightMargin + 0.5);

   if ( $adjLeftMargin > $origLeftMargin ) {
      $adjLeftMargin = $origLeftMargin;
   }
   if ( $adjRightMargin > $origRightMargin ) {
      $adjRightMargin = $origRightMargin;
   }
   return ( $adjLeftMargin, $adjRightMargin );
}

sub GetAdjustedMargin #($adjustedTotalMargin, $origLeftMargin, $origRightMargin)

#
# RETURN:
#  ($adjustedLeftMargin, $adjustedRightMargin) that satisfy the followings
#    - $adjustedLeftMargin / $adjustedRightMargin ~ $origLeftMargin / $origRightMargin
{
   my ( $adjustedTotalMargin, $origLeftMargin, $origRightMargin ) = @_;

   my ( $adjLeftMargin, $adjRightMargin, $origTotalMargin );

   $origTotalMargin = $origLeftMargin + $origRightMargin;

   if ( $origTotalMargin <= 0 ) {
      $adjLeftMargin  = $adjustedTotalMargin / 2;
      $adjRightMargin = $adjustedTotalMargin - $adjLeftMargin;
   }
   else {
      $adjLeftMargin =
        $origLeftMargin / $origTotalMargin * $adjustedTotalMargin;
      $adjRightMargin = $adjustedTotalMargin - $adjLeftMargin;
   }

   # make the adjusted margins integers
   $adjLeftMargin  = int( $adjLeftMargin + 0.5 );
   $adjRightMargin = int( $adjRightMargin + 0.5 );

   return ( $adjLeftMargin, $adjRightMargin );
}

#================================================================================
sub GetBoundingRectForTaggedRect    #($xmlRects, \@boundRect)
                                    #
                                    # A rectangle is represented by an array
                                    #   [0]: x
                                    #   [1]: y
                                    #   [2]: width
                                    #   [3]: height
{
   my ( $xmlRects, $raBoundRect ) = ( shift, shift );

   my @aorRects = ();               # array of ref to rectangles

   GetRectangles( $xmlRects, \@aorRects );

   CalcBoundingRectangles( \@aorRects, $raBoundRect );

   #	#DEBUG
   #	foreach my $r (@aorRects) {
   #		print "$r->[0]\t$r->[1]\t";
   #		print $r->[2]+$r->[0];
   #		print "\t";
   #		print $r->[3]+$r->[1]."\n";
   #	}
   #	print "------------------------------------\n";
   #	print "$raBoundRect->[0]\t$raBoundRect->[1]\t";
   #	print $raBoundRect->[2]+$raBoundRect->[0];
   #	print "\t";
   #	print $raBoundRect->[3]+$raBoundRect->[1]."\n";
}

#================================================================================
sub GetRectangles    #($xmlRects, \@raoaRects)
# Get the rectangles from the "taggedRectangle" elements
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
sub AdjustTaggedRectangleElems    #($xmlRects, $xShift, $yShift, $scalingFactor)
# Adjust
{
   my ( $xmlRects, $xShift, $yShift, $scalingFactor) = @_;

   foreach my $r ( $xmlRects->children("taggedRectangle") ) {
      my $rhAttr = $r->atts();    # ref to hash of the attributes
      
#      $rhAttr->{'x'} += $xShift; 
#      $rhAttr->{'y'} += $yShift;     
#      $rhAttr->{'x'} = int($rhAttr->{'x'} * $scalingFactor + 0.5);
#      $rhAttr->{'y'} = int($rhAttr->{'y'} * $scalingFactor + 0.5);       
#      $rhAttr->{'width'} = int($rhAttr->{'width'} * $scalingFactor + 0.5);
#      $rhAttr->{'height'} = int($rhAttr->{'height'} * $scalingFactor + 0.5);
      
      $r->set_att('x', int(($rhAttr->{'x'} + $xShift) * $scalingFactor + 0.5),
                  'y', int(($rhAttr->{'y'} + $yShift) * $scalingFactor + 0.5),
                  'width', int($rhAttr->{'width'} * $scalingFactor + 0.5),
                  'height', int($rhAttr->{'height'} * $scalingFactor + 0.5));      
   }
}

#================================================================================
sub PrintUsage {
   print
"Usage: GenTestImgAtResolution.pl <segmentation_XML_file> <output_dir> <target_resolution>\n";
   print " ARGUMENTS:\n";
   print "   <target_resolution>: in the format of <>width>x<height>\n";
}
