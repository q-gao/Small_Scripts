#!/usr/bin/perl
#
# This script gets the average rate info for specified flow Ids from the FLM log.
#
# USAGE: GetMuxThroughputFromFlmLog.pl -f <FLM_Log_File> [-s <StartSF> -n <NumSF> [-r <ReportDur>]]
#
#

use strict;

our ($IDX_NUMSF,
     $IDX_MUXTHR,  # MUX Throughput
    )=(0, 1);

my ($fnmFlmLog, $startSFChked, $numSFChked, $numSFReport); # ARGUMENTS

my ($endSFChked, $tkn, $fhLog, $ln, $wd, @muxThr);

# ARGUMENTS processing
if($#ARGV<1){
   print "USAGE: $0 -f <FLM_Log_File> [-s <StartSF> -n <NumSF> [-r <ReportDur>]]\n";
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
            GenerateReport(\@muxThr);
            undef(@muxThr);
         }
      }elsif($ln=~m{TotalThroughput\s+with\s+FLO\s+OH\s+\((\d+)\)kbps,}x){
         $muxThr[$IDX_NUMSF]++;
         $muxThr[$IDX_MUXTHR]+=$1;
      }
   }
}

close($fhLog);

if( defined(@muxThr) ){
   GenerateReport(\@muxThr);
}

sub   GenerateReport #()
{
   my $raStat=shift;

   if($raStat->[$IDX_NUMSF]>0){
      $raStat->[$IDX_MUXTHR]/=$raStat->[$IDX_NUMSF];
   }else{
      $raStat->[$IDX_MUXTHR]=0;
   }
   print "\n NumSF  MuxThroughput\n";
   print   "------  -------------\n";
   printf "%6d  %13.2f\n", $raStat->[$IDX_NUMSF], $raStat->[$IDX_MUXTHR];
}

