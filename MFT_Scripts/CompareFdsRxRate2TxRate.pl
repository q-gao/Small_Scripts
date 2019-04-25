#!/usr/bin/perl
#
# USAGE:
#  $0 -m <MLC_ID> -i <flow_id> -d <device_log_file> -f <FLM_log_file>
use strict;
use Time::Local;
use File::Basename;

our $dirSeparator="\/";  # for UNIX/Linux/Cygwin
#our $dirSeparator="\\";  # for DOS
my  $MYGREP="MyGrep.pl";

our ($FLD_SFID,
     $FLD_TX_RATE,
     $FLD_RX_RATE,
     $FLD_ERASURE_RATE
     )= (0, 1, 2, 3);

#----------------------------------------
if($#ARGV<7){
   PrintUsage(); exit(-1);
}

my ($tkn, $mlcId, $flowId, $fnmQxdmLog, $fnmFlmLog);

while(defined($tkn=shift(@ARGV))){
   if(    $tkn eq "-m"){
      $mlcId=shift(@ARGV);
   }elsif($tkn eq "-i"){
      $flowId=shift(@ARGV);
   }elsif($tkn eq "-d"){
      $fnmQxdmLog=shift(@ARGV);
   }elsif($tkn eq "-f"){
      $fnmFlmLog=shift(@ARGV);
   }
}

InitUTCToGpsTimeConverter();

my $dirPrgm=dirname($0);
$MYGREP="$dirPrgm$dirSeparator$MYGREP";

# Get number of PLPs received by devices at each SF
#-----------------------------------------------------
my (@logLines, $cmd, @rxRateInfo, @txRateInfo, @txrxRateInfo );
$cmd="perl $MYGREP -n 12 -e \"\\s+MLC_ID:\\s*$mlcId\\s+Sys:\\s*\\d+\\s+-\\s*Frame\\s+#\\s*4\" $fnmQxdmLog".
     "|".
     "perl $MYGREP -p 1 -e \"\\d+\\s+base\\s+data\\s+erasures:\\s*\\d+\"";
#print "$cmd\n";
@logLines=`$cmd`;
#print @logLines;
GrabFdsRxPlp(\@logLines,\@rxRateInfo);
undef(@logLines);
#foreach (@rxRateInfo) { print join(" ",@{$_})."\n";}

# Get number of PLPs transmitted by MUX at each SF
#-----------------------------------------------------
if( $#rxRateInfo<0){
   print "ERROR: Device log $fnmQxdmLog doesn't have rx rate info for MLC $mlcId\n";
}else{
   GrabMuxTxRate( $fnmFlmLog, $flowId,
                  $rxRateInfo[0][0],
                  $rxRateInfo[$#rxRateInfo][0],
                  \@txRateInfo);
   #foreach (@txRateInfo) { print join(" ",@{$_})."\n";}
   MergeTxRxRateInfo(\@txRateInfo, \@rxRateInfo, \@txrxRateInfo);
   #foreach (@txrxRateInfo) { print join(" ",@{$_})."\n";}
   undef(@txRateInfo); undef(@rxRateInfo);
   OutputTxRxRateInfo(\@txrxRateInfo);
}


#================================================================================
# SUB
#================================================================================
sub   PrintUsage{
   print "USAGE: $0 -m <MLC_ID> -i <flow_id> -d <device_log_file> -f <FLM_log_file>\n";
}
sub OutputTxRxRateInfo#(\@txrxRateInfo);
{
   my $raTxRx=shift;

   my ($ii, $sfRef, $cumTx, $cumRx, $cumEras);
   if( $#{$raTxRx}<0) {return;}

   print "SF_ID,SfIndex,TxRate,RxRate_Good,Erasure,CumTxRate,CumRxRate,CumErasure\n";

   $sfRef=$raTxRx->[0][$FLD_SFID]; $cumTx=0; $cumRx=0; $cumEras=0;
   foreach ( $ii=0; $ii<= $#{$raTxRx}; $ii++ ) {
      $cumTx+=$raTxRx->[$ii][$FLD_TX_RATE];
      $cumRx+=$raTxRx->[$ii][$FLD_RX_RATE];
      $cumEras+=$raTxRx->[$ii][$FLD_ERASURE_RATE];

      print "$raTxRx->[$ii][$FLD_SFID],".
            eval($raTxRx->[$ii][$FLD_SFID]-$sfRef).
            ",$raTxRx->[$ii][$FLD_TX_RATE],$raTxRx->[$ii][$FLD_RX_RATE],".
            "$raTxRx->[$ii][$FLD_ERASURE_RATE],$cumTx,$cumRx,$cumEras\n";
   }
}
sub MergeTxRxRateInfo #(\@txRateInfo, \@rxRateInfo, \@txrxRateInfo)
{
   my ($raTx, $raRx, $raTxRx)=
      (shift, shift, shift);

   my (%h, $ii);

   foreach ( @{$raTx}) {
      $h{$_->[0]}->[$FLD_TX_RATE]=$_->[1];
   }
   foreach ( @{$raRx}) {
      $h{$_->[0]}->[$FLD_RX_RATE]=$_->[1];
      $h{$_->[0]}->[$FLD_ERASURE_RATE]=$_->[2];
   }

   $ii=0;
   foreach ( sort {$a<=>$b} keys(%h) ) {
      $raTxRx->[$ii][$FLD_SFID] = $_;
      if( defined($h{$_}->[$FLD_TX_RATE])){
         $raTxRx->[$ii][$FLD_TX_RATE] = $h{$_}->[$FLD_TX_RATE];
      }else{
         $raTxRx->[$ii][$FLD_TX_RATE]=0;
      }
      if( defined($h{$_}->[$FLD_RX_RATE])){
         $raTxRx->[$ii][$FLD_RX_RATE] = $h{$_}->[$FLD_RX_RATE];
      }else{
         $raTxRx->[$ii][$FLD_RX_RATE]=0;
      }
      if( defined($h{$_}->[$FLD_ERASURE_RATE])){
         $raTxRx->[$ii][$FLD_ERASURE_RATE] = $h{$_}->[$FLD_ERASURE_RATE];
      }else{
         $raTxRx->[$ii][$FLD_ERASURE_RATE]=0;
      }
      $ii++;
   }
}
sub GrabFdsRxPlp #(\@logLines, @results)
{
   my ($raLogs, $raRst)=(shift, shift);

   my ($line, $sfId);
   foreach $line( @{$raLogs} ){
      if($line=~/^\s*(\d+\s+\w+\s+\d+\s+\d+:\d+:\d+)/){
         $sfId = ConvUTCToGpsTime(\$1);
      }elsif($line=~/\s+PLPs:\s*(\d+)\s+base\s+data\s+erasures:\s*(\d+)/){
         push(@{$raRst}, [$sfId, $1, $2]);
      }
   }
}

sub GrabMuxTxRate #( $fnm, $flowId, $sfStar, $sfEnd, \@txRateInfo)
{
   my ($fnm, $flowId, $sfStart, $sfEnd, $raTxRateInfo)=
      (shift, shift, shift, shift, shift);

   my ($fh, $bValid, $line, $sfCur);
   $bValid=0;

   if(!open($fh, "<$fnm")){
      print "FAILED to open file $fnm\n"; exit(-1);
   }

   while($line=<$fh>){
      if($line=~/STATSSample\s*:\s*SF\((\d+)\)/){
         $sfCur=$1;
         if($sfCur>$sfEnd){ last;}
         if($sfCur>=$sfStart){ $bValid=1;}
      }elsif($bValid){
         if($line=~m{STATSSample\s*:\s*FlowId\($flowId\)\s*
                     Req\/Granted\/Actual\s+Rates\((\d+)\/(\d+)\/(\d+)\)}x){
            push( @{$raTxRateInfo}, [$sfCur, $3]);
         }
      }
   }

   close($fh);
}
#-------------------------------------------------------------------------
# Global variable for UTC to GPS time conversion
our $LEAP_SECONDS;
our ($secsGpsUnix, $LEAP_SECONDS, %monthToMonthId);

sub InitUTCToGpsTimeConverter
{
	# Just for Windows
#	Date_Init("TZ=PST8PDT");
#	my $utcUnixEpoch="Jan 1, 1970 00:00:00 GMT";
#	my $utcGpsEpoch="Jan 6, 1980 00:00:00 GMT";
#	my $unixtmUnixEpoch = UnixDate(ParseDate($utcUnixEpoch),"%s");
#	my $unixtmGpsEpoch = UnixDate(ParseDate($utcGpsEpoch),"%s");
#
	# funciton timegm from Time::Local module converts GMT time to UNIX time

	# UNIX epoch time: "Jan 1, 1970 00:00:00 GMT";
	#my $unixtmUnixEpoch = timegm(0,0,0, # sec, min, hour
	#									  1,0,   # day (1-31), month (0-11)
	#								  	  1970   # year
	#									);

	# GPS epoch: "Jan 6, 1980 00:00:00 GMT";
	#----------------------------------------------
	$secsGpsUnix = timegm(0,0,0, # sec, min, hour
								 6,0,  # day (1-31), month (0-11)
								 1980 # year
							 );

	# Leap seconds between UTC and GPS time
	$LEAP_SECONDS = 14;

	%monthToMonthId=(
			"JAN"=>0,
			"FEB"=>1,
			"MAR"=>2,
			"APR"=>3,
			"MAY"=>4,
			"JUN"=>5,
			"JUL"=>6,
			"AUG"=>7,
			"SEP"=>8,
			"OCT"=>9,
			"NOV"=>10,
			"DEC"=>11,

	);

}

sub ConvUTCToGpsTime #( \$utc)
#Example $utc
# "2007 Aug  4     18:42:02.996" format used in QXDM log
{
	if(${$_[0]} =~ m{(\d+)\s+	# $1: Month
						  (\w+)\s+ # $2: Day
						  (\d+)\s+	# $3: Year
						  (\d+):(\d+):(\d+) # $4 $5 $6
							}x){
      #print "$1 $2 $3 $4 $5 $6\n";
		return	timegm($6, $5, $4,
							 $3,  # day
                      $monthToMonthId{uc($2)},  # month
							 $1   # year
						 )-$secsGpsUnix +$LEAP_SECONDS;
	}else{
		return -1;
	}

#	return UnixDate(ParseDate(${$_[0]}),"%s")- $secsGpsUnix +$LEAP_SECONDS;
}
