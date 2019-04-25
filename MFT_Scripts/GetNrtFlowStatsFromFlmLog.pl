#!/usr/bin/perl
#
# This script gets the average rate info for specified flow Ids from the FLM log.
#
# USAGE: GetNrtFlowStatFromFlmLog.pl -f <FLM_Log_File> [-s <StartSF> -n <NumSF> [-r <ReportDur>]]
#        it reads flow Ids from STDIN
#

use strict;

our ($IDX_REQOCCUR,
    $IDX_GRNOCCUR,
    $IDX_GRNOCCUR_MED,
    $IDX_GRNOCCUR_LOW,
    $IDX_GRNRATE_MED,
    $IDX_GRNRATE_LOW,
    )=(0, 1, 2, 3, 4, 5);
our ($IDX_NUMSF,
     $IDX_MUXTHR,  # MUX Throughput
    )=(0, 1);

my ($fnmFlmLog, $startSFChked, $numSFChked, $numSFReport); # ARGUMENTS

my ($endSFChked, $tkn, $fhLog, $ln, $wd, @flowIds, %flowIdsChk, %flowInfo,
    @muxThr, $fid);

# ARGUMENTS processing
if($#ARGV<1){
   print "USAGE: GetFlowRatesFromFlmLog.pl -f <FLM_Log_File> [-s <StartSF> -n <NumSF> [-r <ReportDur>]]\n";
   print "\tFlow Ids are entered in STDIN. One Id per line\n";
   exit(-1);
}

while( defined($tkn=shift(@ARGV)) ){
   if( $tkn eq "-f" ){
      $fnmFlmLog = shift(@ARGV);
   }elsif( $tkn eq "-s" ){
      $startSFChked = eval( shift(@ARGV) );
   }elsif( $tkn eq "-n" ){
      $numSFChked = eval( shift(@ARGV) );
   }elsif( $tkn eq "-r" ){
      $numSFReport = eval( shift(@ARGV) );
   }
}

if( !defined($fnmFlmLog) ){
   die "ERROR: no FLM log file specified\n";
}

if( !defined($startSFChked) ){
   my    @arHd = `head -500 $fnmFlmLog | grep "SF("`;
   foreach(@arHd){
      if( /\s+SF\((\d+)\)/ ){
         $startSFChked = $1;  last;
      }
   }
   undef(@arHd);
}

if( !defined($startSFChked) ){
   die   "ERROR: can't find any SF Id in the first 500 lines of $fnmFlmLog\n";
}

if( !defined($numSFChked) ){
   $numSFChked = 60;
}

if( !defined($numSFReport) ){
   $numSFReport = $numSFChked;
}

$endSFChked = $startSFChked+$numSFChked-1;

#print "$fnmFlmLog $startSFChked $numSFChked\n"; exit(-1);

# read flow Ids from STDIN
while(<STDIN>){
   if(/(\d+)/){
      $fid=$1;
     push(@flowIds, $fid);
     $flowIdsChk{$fid}=1;
   }
}

# processing FLM log
die "FAILED to open FLM log file $fnmFlmLog\n" unless open($fhLog,"<$fnmFlmLog");

my ($validData, $sfReport);
$validData = 0; $sfReport = $startSFChked + $numSFReport;

while($ln=<$fhLog>){
   if( $validData == 0 ){
      if( $ln=~/\s+SF\((\d+)\)/ ){
         if( $1<$startSFChked ){
            next;
         }elsif($1<=$endSFChked){
            $validData = 1;
         }else{
            last;
         }
      }
   }else{
      if( $ln=~/\s+SF\((\d+)\)/ ){
         if($1 > $endSFChked){   last; }
         if($1>=$sfReport){
            $sfReport+=$numSFReport;
            GenerateReport(\@flowIds, \%flowInfo, \@muxThr);
            undef(%flowInfo); undef(@muxThr);
         }
      }elsif($ln=~/FlowId\((\d+)\)/){
         # ... : FlowId(8944) Requested/Granted Per Prio ... HIGH(0/0) MED(0/0) LOW(162/0) BE(0/0) kbps
         if($flowIdsChk{$1}){
            $fid=$1;
            if($ln=~/MED\((\d+)\/(\d+)\)\s*LOW\((\d+)\/(\d+)\)/){
               if($1+$3>0){
                  $flowInfo{$fid}->[$IDX_REQOCCUR]++;

                  if($2+$4>0){
                     $flowInfo{$fid}->[$IDX_GRNOCCUR]++;
                     if($2>0){
                        $flowInfo{$fid}->[$IDX_GRNOCCUR_MED]++;
                        $flowInfo{$fid}->[$IDX_GRNRATE_MED]+=$2;
                     }
                     if($4>0){
                        $flowInfo{$fid}->[$IDX_GRNOCCUR_LOW]++;
                        $flowInfo{$fid}->[$IDX_GRNRATE_LOW]+=$4;
                        #print "$flowInfo{$fid}->[$IDX_GRNOCCUR_LOW] $4 $flowInfo{$fid}->[$IDX_GRNRATE_LOW] ";
                        #print $flowInfo{$fid}->[$IDX_GRNRATE_LOW]/
                        #      $flowInfo{$fid}->[$IDX_GRNOCCUR_LOW]."\n";
                     }
                  }
               }
           } # End of MED LOW Line processing
         }
      }elsif($ln=~m{TotalThroughput\s+with\s+FLO\s+OH\s+\((\d+)\)kbps,}x){
         $muxThr[$IDX_NUMSF]++;
         $muxThr[$IDX_MUXTHR]+=$1;
      }
   }
}

close($fhLog);

if(defined(%flowInfo)){
   GenerateReport(\@flowIds, \%flowInfo, \@muxThr);
}


#===================================================================
sub GenerateReport #(\@flowIds, \%flowInfo, \@$muxThr)
{

   my ($raFlowIds, $rhFlowInfo, $raMuxStat);
   $raFlowIds=shift; $rhFlowInfo=shift; $raMuxStat = shift;

   my ($fid, $cnt, $grnProb, $medPcnt, $txData);
   $cnt=0;
   print "\nFlowId  NumReqSF  NumGrnSF  GrantProb    GrnRate_Med  GrnRate_Low  NumTxKByte  MedTxBits_%\n";
   print   "------  --------  --------  ---------    -----------  -----------  ----------  -----------\n";
   foreach $fid (@{$raFlowIds}) {
      if(defined($rhFlowInfo->{$fid})){
         $cnt++;
         if($rhFlowInfo->{$fid}->[$IDX_REQOCCUR]>0){
            $grnProb=$rhFlowInfo->{$fid}->[$IDX_GRNOCCUR]/
                     $rhFlowInfo->{$fid}->[$IDX_REQOCCUR];
         }else{
            $grnProb = 0;
         }
         # Note: $IDX_GRNRATE_MED and $IDX_GRNRATE_LOW will be converted
         #       to rate below.
         $txData=$rhFlowInfo->{$fid}->[$IDX_GRNRATE_MED]+
                 $rhFlowInfo->{$fid}->[$IDX_GRNRATE_LOW];
         if($txData>0){
            $medPcnt=$rhFlowInfo->{$fid}->[$IDX_GRNRATE_MED]/$txData;
         }else{
            $medPcnt=0.0;
         }

         if($rhFlowInfo->{$fid}->[$IDX_GRNOCCUR_MED]>0){
            $rhFlowInfo->{$fid}->[$IDX_GRNRATE_MED]/=
            $rhFlowInfo->{$fid}->[$IDX_GRNOCCUR_MED];
         }
         if($rhFlowInfo->{$fid}->[$IDX_GRNOCCUR_LOW]>0){
            $rhFlowInfo->{$fid}->[$IDX_GRNRATE_LOW]/=
            $rhFlowInfo->{$fid}->[$IDX_GRNOCCUR_LOW];
         }
         printf "%6d  %8d  %8d  %9.4f    %11.3f  %11.3f  %10d  %11.3f\n",
               $fid,
               $rhFlowInfo->{$fid}->[$IDX_REQOCCUR],
               $rhFlowInfo->{$fid}->[$IDX_GRNOCCUR],
               $grnProb,
               $rhFlowInfo->{$fid}->[$IDX_GRNRATE_MED],
               $rhFlowInfo->{$fid}->[$IDX_GRNRATE_LOW],
               $txData/8,
               $medPcnt;

      }else{
         printf "%6d  --  --  --  --  --  --  --  --\n",$fid;
      }
   }

   if($raMuxStat->[$IDX_NUMSF]>0){
      $raMuxStat->[$IDX_MUXTHR]/=$raMuxStat->[$IDX_NUMSF];
   }else{
      $raMuxStat->[$IDX_MUXTHR]=0;
   }
   printf "%d flows found in the FLM logs. MUX Throughput = %.2f".
          " over %d SFs\n",
         $cnt,$raMuxStat->[$IDX_MUXTHR],$raMuxStat->[$IDX_NUMSF];
}



