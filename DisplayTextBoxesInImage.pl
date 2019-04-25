#!/usr/bin/perl
#
# Draw a 50% transparent (alpha value) rectangle. Color can be "none" "transparent"
# convert aPICT0034.JPG -fill "graya( 50%, 0.5)" -stroke white -draw "rectangle 20,10 300,350" t.jpg
#
# Draw an image over color background
#  convert -size 800x800 xc:skyblue -gravity center -draw "image over 0,0 0,0 'aPICT0034.JPG'" t.jpg
# 

#
# Usage:
#  DisplayTextBoxesInImage.pl <segmentation_XML_file> [<displayed_image_file_base_names>]
#
use strict;
use XML::Twig;
use File::Basename;
use threads;  # Perl needs to be compiled to support threading. see https://wiki.bc.net/atl-conf/pages/viewpage.action?pageId=20548191
use threads::shared;

#-----------------------------------------------------------------------
# parse arguments
if ( $#ARGV < 0 ) {
	PrintUsage();
	exit(-1);
}

my %hDispImgBaseName;
if($#ARGV >= 1) {
   foreach (@ARGV[1 .. $#ARGV]) {
      $hDispImgBaseName{$_} = 1;      
   }
}

our ($inRootDir, $segXmlBaseName);
$inRootDir = dirname($ARGV[0]);
$segXmlBaseName = basename($ARGV[0]);

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
   if($#ARGV < 1 ||
      exists($hDispImgBaseName{basename($img->first_child("imageName")->text())})) {   
	  ProcXMLImageElem($img);
   }
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
	$cmd .= " - | display -";

    print "\n----------------------------------------------------------------------------------------\n";
    print "$cmd\n----------------------------------------------------------------------------------------\n";
    
	 my $t = threads->new(\&Thread_ExecCommand, $cmd);

     my $in = PromptUser("\nOptions: N=Next, Q=Quit ","N");
     my @pids = GetProcessID("display"); # NOTE: should not look for "convert"
     foreach (@pids) {
       system("kill -KILL $_ >/dev/null");
     }
	 
	 #$t->join(); #join cause problem??
     if(uc($in) eq "Q") {
		last;
     }	
}
#========================================================================
sub Thread_ExecCommand # ($cmd)
{
	my $cmd = shift;
    system($cmd);	
}
#========================================================================
sub GetProcessID #($processName)
{
   my ($pname) = @_;
  
   my @psFilteredOut = `ps | grep $pname`;

   #DEBUG
#   print join("", @psFilteredOut);
   
   my @pids = ();
   foreach (@psFilteredOut) {
     chomp;
     if(/^\s*(\d+)/) {
        push(@pids, $1);
     }
   }
   return @pids;
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
#========================================================================
sub PromptUser # ($promptString,$defaultValue)
{
   #-------------------------------------------------------------------#
   #  two possible input arguments - $promptString, and $defaultValue  #
   #  make the input arguments local variables.                        #
   #-------------------------------------------------------------------#

   my ($promptString,$defaultValue) = @_;

   #-------------------------------------------------------------------#
   #  if there is a default value, use the first print statement; if   #
   #  no default is provided, print the second string.                 #
   #-------------------------------------------------------------------#

   if ($defaultValue) {
      print $promptString, "[", $defaultValue, "]: ";
   } else {
      print $promptString, ": ";
   }

   $| = 1;               # force a flush after our print
   $_ = <STDIN>;         # get the input from STDIN (presumably the keyboard)


   #------------------------------------------------------------------#
   # remove the newline character from the end of the input the user  #
   # gave us.                                                         #
   #------------------------------------------------------------------#

   chomp;

   #-----------------------------------------------------------------#
   #  if we had a $default value, and the user gave us input, then   #
   #  return the input; if we had a default, and they gave us no     #
   #  no input, return the $defaultValue.                            #
   #                                                                 # 
   #  if we did not have a default value, then just return whatever  #
   #  the user gave us.  if they just hit the <enter> key,           #
   #  the calling routine will have to deal with that.               #
   #-----------------------------------------------------------------#

   if ("$defaultValue") {
      return $_ ? $_ : $defaultValue;    # return $_ if it has a value
   } else {
      return $_;
   }
}

#================================================================================
sub PrintUsage {
	print
"DisplayTextBoxesInImage.pl <segmentation_XML_file> <displayed_image_file_base_name>\n";
}
