#!/usr/bin/perl
#
use strict;
use XML::Twig;	# a subclass of XML::Parser
use File::Basename;

our	$msgEncodeXmlFile="MessageCoding.xml";
our	$dirSep="/";

if($#ARGV<0){
	print "Usage: $0 <Clip_Size_in_bytes> [clipcast_rate_in_bps]\n";
	exit(-1);
}

my $dirPrgm=dirname($0);

my $clipSize= eval(shift(@ARGV));
my $clipcastRate;
if($#ARGV>=0){
	$clipcastRate=eval(shift(@ARGV));
}else{
	$clipcastRate =256000; # 256kbps
}


my $msgEncXmlFilePath = "$dirPrgm$dirSep$msgEncodeXmlFile";
if(!(-f $msgEncXmlFilePath)){
	print "ERROR: $msgEncodeXmlFile doesn't exist in $dirPrgm\n";
	exit(-2);
}

my @para=GetFDPPayloadSize($clipSize, \$msgEncXmlFilePath);
if($#para>0){
	my $bwDur = $clipSize * 8 *  $para[0]/$clipcastRate;
	print "( N/K , BW_Dur ) = ($para[0] , $bwDur)\n";
	my $contactDur = $clipSize * 8 * (1+$para[1])/$clipcastRate;
	print "( MinEpsilon/MaxEpsilon , Contact_Dur ) = ($para[1]/$para[2] , $contactDur)\n";
	print "Pkt Payload Size = $para[3] bytes\n";
}else{
	print "clip size $clipSize is too big\n";
}

#=================================================================
sub GetFDPPayloadSize #($clipSize, \$msgCodingXmlFilePath)
{
   my $file_size = shift;
   my $refMsgCodeXml = shift;

   my $t = XML::Twig->new( );
   $t->parsefile( $$refMsgCodeXml );

   my @settings = $t->root->children('MessageCodingData');
   my $i = 0;
   foreach my $setting (@settings) {
	   if ($file_size >= $setting->first_child('MinFileSize')->text &&
        $file_size <= $setting->first_child('MaxFileSize')->text ) {

		  my @epsilon = $setting->children('EpsilonRange');
		  #print $epsilon[0]->first_child('MinEpsilon')->text;
		  #print " ";
		  #print $epsilon[0]->first_child('MaxEpsilon')->text;
		  #print "\n";

		  #return $setting->first_child('PayloadSize')->text;
		  return ($setting->first_child('N_Over_K')->text,
		  			 $epsilon[0]->first_child('MinEpsilon')->text,
				 	 $epsilon[0]->first_child('MaxEpsilon')->text,
				    $setting->first_child('PayloadSize')->text);
     }
   }
}




