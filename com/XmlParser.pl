#!/usr/bin/perl
#
# Some common sub's for parsing the XML files used in OCR, e.g., ICDAR ground truth XML files, result XML files and etc.
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

#========================================================================
sub GenHashFromOcrXmlResult    #(\$xmlResultFile, $rhashImg2Char)

# RETURN:
#  Reference to a hash table each of whose elements
#    $h{<file_name>} = [[<truthChar>,<cost>],[<candidate_1, cost_1>], [<candidate_, cost_2>] ...]]
#    <cost_of_correspondingletter> = -1 if the letter is not in the candiate list
#
{
   my ( $rXmlResultFile, $rhImg2Char ) = @_;

   my $rhImg2Result = {};

   my $xmlResult = XML::Twig->new();
   $xmlResult->parsefile( ${$rXmlResultFile} )
     ;    # it will die if the file doesn't exist
   my @aImgs = $xmlResult->root->children("image");
   foreach my $img (@aImgs) {
      __ProcImgElementInOcrXmlResult($img, $rhImg2Result, $rhImg2Char);
   }
   
   return $rhImg2Result;
}

#----------------------------------------------------------------------
sub __ProcImgElementInOcrXmlResult    #($imgElem, $rhImg2Result, $rhashImg2Char)

  #RETURN:
  #   0 : success
  #   -1: the image doesn't have ground truth
{
   my ( $imgElem, $rhImg2Result, $rhImg2Char ) = @_;

   my $imgBasename = basename( $imgElem->first_child("gt_path")->text() );

   if ( !exists( $rhImg2Char->{$imgBasename} ) ) {
      return -1;
   }
   my $charTruth = lc($rhImg2Char->{$imgBasename}); ################# case insensitive
   $rhImg2Result->{$imgBasename}->[0] = [$charTruth, -1]; 
   
   my @candidates = $imgElem->children("candidate");
   my ( $ii, $charCand, $cost );
   $ii = 1;
   foreach my $cand (@candidates) {
      $charCand = lc( $cand->first_child("character")->text() ); ################# case insensitive
      $cost     = $cand->first_child("cost")->text();
      $rhImg2Result->{$imgBasename}->[$ii] = [ $charCand, $cost ];
      
      if ( $charTruth eq $charCand ) {    
         $rhImg2Result->{$imgBasename}->[0] = [ $charTruth, $cost ];         
      }

      $ii++;
   }

   return 0;
}

#========================================================================
sub GenHashFromCharXml    #(\$charXmlFile)

# RETURN: reference to a hash table mapping an image file name to the letter it represent, i.e.,
#  $h{<file_name>} = <the corresponding letter>
{
   my $fhXml;

   open $fhXml, "<${$_[0]}" or die $!;

   my $rhFilename2Char = {};

   while (<$fhXml>) {
      chomp;
      if (/file\s*=\s*\"(.+)\"\s+tag\s*=\s*\"(.+)\"/) {
         $rhFilename2Char->{$1} = $2;
      }
   }

   close $fhXml;

   return $rhFilename2Char;
}

1;    # needed!
