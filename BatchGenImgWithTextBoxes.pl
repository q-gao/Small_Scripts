#/usr/bin/perl
# 
# Generate images with the shown text boxes
#
# Usage:
#  BatchGenImgWithTextBoxes.pl <segmentation_XML_file> <out_dir>
#
use strict;
use XML::Twig;
use File::Basename;
use List::Util qw[min max];

#-----------------------------------------------------------------------
# parse arguments
if ( $#ARGV < 1 ) {
	PrintUsage();
	exit(-1);
}

our ($inRootDir, $segXmlBaseName, $outRootDir);
$inRootDir = dirname($ARGV[0]);
$segXmlBaseName = basename($ARGV[0]);

$outRootDir = $ARGV[1];
$outRootDir =~ s/\/$//; # remove trailing "/" if there is one

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
# save the XML file for the generated images
#my $fhOutSegXml;
#open $fhOutSegXml, ">$outRootDir/$segXmlBaseName" or die $!;
#$origSegXml->print($fhOutSegXml);
#$origSegXml->flush();

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
	my $imgName = $img->first_child("imageName")->text();
	my $imgBaseName = basename($imgName);

  #<taggedRectangles>
  #-----------------------------------------------------------------------------
	my $xmlRects = $img->first_child("taggedRectangles");
	my @arRects;
	GetRectangles($xmlRects, \@arRects);
	
	my $cmd = "convert $inRootDir/$imgName -fill \"graya( 50%, 0.5)\" -stroke white";
	foreach my $rar (@arRects) {
		my ($x, $y) = ($rar->[0]+$rar->[2]-1, $rar->[1]+$rar->[3]-1);
		$cmd .= " -draw \"rectangle $rar->[0],$rar->[1] $x,$y\"";
	}
	$cmd .= " $outRootDir/$imgBaseName";

	print "\n$cmd\n";
	system($cmd);

}
#================================================================================
sub GetRectangles    #($xmlRects, \@raoaRects)
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
"BatchGenImgWithTextBoxes.pl <segmentation_XML_file> <out_dir>\n";
}
