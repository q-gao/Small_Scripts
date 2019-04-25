#!/usr/bin/perl
#
# This script gets the average rate info for specified flow Ids from the FLM log.
#
# USAGE: GetFlowRatesFromFlmLog.pl -f <FLM_Log_File> [-s <StartSF> -n <NumSF> [-r <ReportDur>]]
#        it reads flow Ids from STDIN
#

use strict;

our ($IDX_OCCUR,
    $IDX_REQRATE,
    $IDX_GRNRATE,
    $IDX_ACTRATE,
    $IDX_CNTREENC,   # reencoding
    $IDX_GRN_RATEREDUC,  # Granted Rate Reduction Ratio
    $IDX_ACT_RATEREDUC,  # Actual Rate Reduction Ratio
    )=(0, 1, 2, 3, 4, 5, 6);
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
      }elsif($ln=~/FlowId\((\d+)\)\s+Req\/Granted\/Actual\s+Rates\((\d+)\/(\d+)\/(\d+)\)kbps/){
         #FlowId(4464) Req/Granted/Actual Rates(0/0/0)kbps
         #$fid = $1; $rr= $2; $gr=$3; $at=$4;
         if($flowIdsChk{$1}){
            $flowInfo{$1}->[$IDX_OCCUR]++;
            if($2>$3){ # re-encoding
               $flowInfo{$1}->[$IDX_CNTREENC]++;
               if($2>0){
                  $flowInfo{$1}->[$IDX_GRN_RATEREDUC]+=(($2-$3)/$2);
                  $flowInfo{$1}->[$IDX_ACT_RATEREDUC]+=(($2-$4)/$2);
               }
            }
            $flowInfo{$1}->[$IDX_REQRATE]+=$2;
            $flowInfo{$1}->[$IDX_GRNRATE]+=$3;
            $flowInfo{$1}->[$IDX_ACTRATE]+=$4;
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


sub GenerateReport #(\@flowIds, \%flowInfo, \@$muxThr)
{

   my ($raFlowIds, $rhFlowInfo, $raMuxStat);
   $raFlowIds=shift; $rhFlowInfo=shift; $raMuxStat = shift;

   my ($fid, $cnt);
   $cnt=0;
   print "\nFlowId  Occurances  ReqRate  GrnRate  ActRate  ReencProb  GrnRateReduc_%  ActRateReduc_%  UnusedRate\n";
   print   "------  ----------  -------  -------  -------  ---------  --------------  --------------  -----------\n";
   foreach $fid(@{$raFlowIds}) {
      if(defined($rhFlowInfo->{$fid})){
         $cnt++;

         if( $rhFlowInfo->{$fid}->[$IDX_CNTREENC]>0 ){ # NOTE: CNTREENC is converted to reenc prob below
            $rhFlowInfo->{$fid}->[$IDX_GRN_RATEREDUC]/=$rhFlowInfo->{$fid}->[$IDX_CNTREENC];
            $rhFlowInfo->{$fid}->[$IDX_ACT_RATEREDUC]/=$rhFlowInfo->{$fid}->[$IDX_CNTREENC];
         }

         if( $rhFlowInfo->{$fid}->[$IDX_OCCUR]>0 ){
            $rhFlowInfo->{$fid}->[$IDX_CNTREENC]/=$rhFlowInfo->{$fid}->[$IDX_OCCUR];
            $rhFlowInfo->{$fid}->[$IDX_REQRATE]/=$rhFlowInfo->{$fid}->[$IDX_OCCUR];
            $rhFlowInfo->{$fid}->[$IDX_GRNRATE]/=$rhFlowInfo->{$fid}->[$IDX_OCCUR];
            $rhFlowInfo->{$fid}->[$IDX_ACTRATE]/=$rhFlowInfo->{$fid}->[$IDX_OCCUR];
         }

         printf "%6d  %10d  %7.2f  %7.2f  %7.2f  %9.3f  %14.3f  %14.3f  %10.2f\n",
               $fid, $rhFlowInfo->{$fid}->[$IDX_OCCUR],
                     $rhFlowInfo->{$fid}->[$IDX_REQRATE],
                     $rhFlowInfo->{$fid}->[$IDX_GRNRATE],
                     $rhFlowInfo->{$fid}->[$IDX_ACTRATE],
                     $rhFlowInfo->{$fid}->[$IDX_CNTREENC],
                     $rhFlowInfo->{$fid}->[$IDX_GRN_RATEREDUC],
                     $rhFlowInfo->{$fid}->[$IDX_ACT_RATEREDUC],
                     $rhFlowInfo->{$fid}->[$IDX_GRNRATE]-$rhFlowInfo->{$fid}->[$IDX_ACTRATE];
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



