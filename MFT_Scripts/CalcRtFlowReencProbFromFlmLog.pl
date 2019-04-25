#!/usr/bin/perl
#
# Calculate RT flow re-encoding prob
#

use strict;

if($#ARGV<0){
	print "Usage: $0 <FlowId_Config_file> [Avg_Duration]\n";
	exit(-1);
}

my $flowIdCfgFnm=shift(@ARGV);
my $avgDur;
if($#ARGV>=0){
   $avgDur = shift(@ARGV);
}else{
   $avgDur = 2147483647; # max 32-bit signed int
}
our ($IDX_AUDIO, $IDX_VIDEO) = (0,1);

my (@rtFlows, @clipcastFlows, @ipdcFlows, @mcFlows);
ReadFlowIdFile($flowIdCfgFnm, \@rtFlows, \@clipcastFlows, \@ipdcFlows, \@mcFlows);
my (%rtvInSf, %mcInSf, %ipdcInSf, $cnt);

$cnt = 0;
foreach (@rtFlows) {
   $rtvInSf{$_->[$IDX_VIDEO]} = 0;
   $cnt++;
}
#print join(" ",keys(%rtvInSf)); print "\n";

$cnt = 0;
foreach (@mcFlows) {
   $mcInSf{$_->[$IDX_VIDEO]} = 0;
   $cnt++;
}
#print join(" ",keys(%mcInSf)); print "\n";

$cnt = 0;
foreach (@ipdcFlows) {
   $ipdcInSf{$_} = 0;
   $cnt++;
}
#print join(" ",keys(%ipdcInSf)); print "\n";

# foreach (@rtFlows){
# 	print "$_->[0] $_->[1]\n";
# }
# print "\n";
# print join(" ",@clipcastFlows);
# print "\n";
# print join(" ",@ipdcFlows);
# print "\n";

my ($ln, $sf, $cntSf, $flowId,$ff, $prob,
    $ccReqRate , $ccGrnRate , $ccActRate,
    $ccReqRateMed, $ccGrnRateMed, $ccReqRateLow,$ccGrnRateLow,
    $numReencRtf, $totVsiGrnRate, # Video + Slide + IPDC
    $totIpdcMedRate,$totIpdcLowRate
    );
my  (%rtfReencProb);
$cntSf= 0;
while($ln=<>){
   if($ln=~/SF\((\d+)\)/){
      $sf = $1;
      $cntSf++;
      # print out one average results
      if($cntSf>=$avgDur){
         foreach $ff (keys(%rtvInSf)) {
            $prob = $rtvInSf{$ff}/$cntSf;
            push(@{$rtfReencProb{$ff}},$prob);
            $rtvInSf{$ff} = 0;
         }
         # reset
         $cntSf=0;
      }
   }elsif($ln=~/FlowId\((\d+)\)/){
      $flowId = $1;
      if( defined($rtvInSf{$flowId})){
         # RT Flow
         # -----------------------------------------
         # FlowId(9728) Req/Granted/Actual Rates(0/0/0)kbps
         if($ln=~/Req\/Granted\/Actual\s+Rates\((\d+)\/(\d+)\/(\d+)\)/){
            if($1 > $2){
               $rtvInSf{$flowId}++;
            }
         }
      }
   }
}

# print out RT video flow re-encoding prob
if($cntSf>0){
   #print "========================================================\n";
   #print "RT_Video_Flow  Reenc_Prob\n";
   foreach $ff (keys(%rtvInSf)) {
      $prob = $rtvInSf{$ff}/$cntSf;
      #print "$_ $prob = $rtvInSf{$ff}/$cntSf\n";
      push(@{$rtfReencProb{$ff}},$prob);
   }
}

print "RT_Video_Flow  Reenc_Prob\n";
print "========================================================\n";
foreach $ff (keys(%rtfReencProb)) {
   print "$ff "; print join(" ",@{$rtfReencProb{$ff}}); print "\n";
}

#============================================================================
sub ReadFlowIdFile #($fnm, \@rtvFlowInfo,\@lstClipcastFlows, \@lstIpdcFlows, \@mcFlows)
# Read the info from the Flow Id File
# RETURN:
#			0		    if successful
#			!=0    Error code
#
# The FlowId File format
# --------------------------------------------------------------
#		# Service Name   ServiceID    FlowIDs      TCH Server
#		[RT]
#	   	 cbs1            256      4096 4097    cbs3-wa1-tch1-1
#		# Service Name   ServiceID   FlowIDs(FDP FDCP)
#		[NRTS]
#    	cbs4            416      6656 6657
#		[IPDC]
#		     ds1            311      4976
#		[OH]
#	  		0
#	  		1
{
	my 	($fnm, $rfRtvFlowInfo, $rfClipcastF, $rfIpdcF, $rfMcF);
	$fnm = shift;
   $rfRtvFlowInfo = shift; $rfClipcastF = shift; $rfIpdcF=shift; $rfMcF=shift;

	my		($fh, $line, $st, @wd, $leadEmpty, $numf);

	unless( open( $fh, "<$fnm")  ){
		die	"Failed to open file $fnm\n";
	}

	$numf = 0; 	# number of flows
	$st = "UNKNOWN";
	while( defined( $line = <$fh>) ){
		# skip comment line and empty line
		if( ($line=~/^\s*(#|$)/) || ($line=~/^\s*$/) ) { next;}

		if($line =~ /^\[(\w+)\]/){
			# state transition regardless of current state
			$st = $1;
		}else{
			# state dependent processing
			@wd=split(/\s+/, $line);
			#By default, split preserves empty leading fields
			if( $wd[0] eq '' ){ $leadEmpty=1;}
			else{		$leadEmpty=0;}

			if( $st eq "RT"){
				if($#wd < 4 + $leadEmpty){
					die	"Not enough info for RT flow at: $line";
				}
				push(@$rfRtvFlowInfo, [ $wd[2+ $leadEmpty], $wd[3+ $leadEmpty] ] );
				$numf++;
			}elsif($st eq "NRTS"){
				if($#wd < 3+ $leadEmpty){
					die	"Not enough info for NRT flow at: $line";
				}

				#push(@arrNvFid, [ $wd[2+ $leadEmpty] ]);
				push(@{$rfClipcastF},$wd[2+ $leadEmpty]);
				$numf++;
			}elsif($st eq "IPDC"){
				if($#wd < 2+ $leadEmpty){
					die	"Not enough info for IPDC flow at: $line";
				}

				#push(@arrNvFid, [ $wd[2+ $leadEmpty] ]);
				push(@{$rfIpdcF},$wd[2+ $leadEmpty]);
				$numf++;
			}elsif($st eq "MC"){
				# Music Choice
				if($#wd < 3 + $leadEmpty){
					die	"Not enough info for Music choice flow at: $line";
				}
				push(@$rfMcF, [ $wd[2+ $leadEmpty], $wd[3+ $leadEmpty] ] );
				$numf++;
			}elsif($st eq "OH"){
				# Overhead flows are not considered as they are at constant rates
			}elsif($st eq "UNKOWN"){
			}else{
				die "Unrecognized flow types $st in $fnm\n";
			}
		}
	}
	close($fh);

	return	0;
}



