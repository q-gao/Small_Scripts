#!/usr/bin/perl

use strict;
use POSIX;  #included since Perl 5 for functions like floor, ceil
use Time::Local;

#==================================================================
# Constant and data structure definition
# ==================================================================
our $MEDPRIO_TRIGGER_MARGIN = 2;

# MuxTchStat Line structure
#-----------------------------------------
our ($MTSL_IDX_SF,            # SF ID (relative)
     $MTSL_IDX_MUXTHRPUT,     # MUX THROUGHPUT
     )=(0, 1);
# NRT Flow Record
our (
     # Index
     $NRTFR_IDX_REQRATE_MED,
     $NRTFR_IDX_REQRATE_LOW,
     $NRTFR_IDX_GRNRATE_MED,
     $NRTFR_IDX_GRNRATE_LOW,

     # Num of fields in NRTFR
     $NRTFR_NUM_FLD,
     ) = (0, 1, 2, 3,
          4);
# RT flow record
our $RTR_NUM_FLD=25;

# Delimiting Time Info
our ($DTI_WNDIDX,
     $DTI_DELIMTYPE,
     )=(0,1);

# Clipcast Impact Window Info
our ($CIWI_IMPACTSTART,
     $CIWI_IMPACTEND,
     $CIWI_BWND  # broadcast window
     ) = (0, 1, 2);

#==================================================================
# MAIN
# ==================================================================

# Clipcast broadcast windows
# NOTE: the broadcast windows are assumed to
#        - be non-overlapping
#        - orted in ascending order
#        - a broadcast wnd + spill-over duration don't span hour boundary
#        - inter-wnd gap > spill-over duration (FSN latency)
our ($BWND_STARTIME,
     $BWND_ENDTIME ) = (0, 1);
my @CcBwnd=(# start time, duration
            # Note: its format is converted by ConvCcBwndFormat
            # Clipcast schedule on QVC station
            #-----------------------------------
             ["04:06", 275],
             ["12:46", 153],
             ["34:06", 513],
             ["46:44",  59]
            # Clipcast schedule on STB station
            #-----------------------------------
#             ["04:06", 59],
#             ["09:10", 506],
#             ["21:41", 59],
#             ["34:06", 59],
#             ["39:10", 59],
#             ["44:14", 280],
#             ["52:59", 153]
            );
# Clipcast flow stats
our ($CCSTAT_SPILLOVERPCT,
     $CCSTAT_MEDPCT
     )= (0, 1);

# channel line-up
our ($CLU_NUMRTV,
     $CLU_NUMCC,
     $CLU_NUMIPDC
     )= (0, 1, 2);
my ($tkn,$fnm, @aMuxTchStatFnms, $fsnLatency, @cluInfo, $sfId1st);
my @CcFlowStat;

#-----------------------------------
if($#ARGV<1){
   PrintUsage(); exit(-1);
}

while( defined($tkn=shift(@ARGV)) ){
   if( $tkn eq "-f"){ # MuxTchStat files
      while( defined($tkn=shift(@ARGV)) ){
         push(@aMuxTchStatFnms, $tkn);
      }
   }elsif( $tkn eq "-rtv"){ # number of video channels
      $cluInfo[$CLU_NUMRTV]=shift(@ARGV);
      if( !defined($cluInfo[$CLU_NUMRTV]) || $cluInfo[$CLU_NUMRTV]<1 ){
         print "No correct value following -rtv option\n";
         exit(-2);
      }
   }elsif( $tkn eq "-cc"){ # number of clipcast channels
      $cluInfo[$CLU_NUMCC]=shift(@ARGV);
      if( !defined($cluInfo[$CLU_NUMCC]) || $cluInfo[$CLU_NUMCC]<1 ){
         print "No correct value following -cc option\n";
         exit(-2);
      }
   }elsif( $tkn eq "-ipdc"){ # number of IPDC channels
      $cluInfo[$CLU_NUMIPDC]=shift(@ARGV);
      if( !defined($cluInfo[$CLU_NUMIPDC]) || $cluInfo[$CLU_NUMIPDC]<1 ){
         print "No correct value following -ipdc option\n";
         exit(-2);
      }
   }elsif( $tkn eq "-l"){ # FSN_Latency
      $fsnLatency=shift(@ARGV);
      if( !defined($fsnLatency) || $fsnLatency<1 ){
         print "No correct fsn_latecny value following -l option\n";
         exit(-2);
      }
   }elsif( $tkn eq "-h"){ # HELP
      PrintUsage(); exit(0);
   }
}

if( !defined(@aMuxTchStatFnms) ){
   push(@aMuxTchStatFnms, "-");  # read from STDIN
}

if( !defined($cluInfo[$CLU_NUMRTV]) ){
   print "Num of RTV channels not specified\n"; exit(-1);
}

if( !defined($cluInfo[$CLU_NUMCC]) ){
   print "Num of Clipcast channels not specified\n"; exit(-1);
}

if( !defined($cluInfo[$CLU_NUMIPDC]) ){
   print "Num of IPDC channels not specified\n"; exit(-1);
}

if( !defined($fsnLatency) ){
   print "FSN_Latency not specified\n"; exit(-1);
}

InitUTCToGpsTimeConverter();
ConvCcBwndFormat(\@CcBwnd);
#foreach (@CcBwnd) { print join(" ",@{$_})."\n";}

foreach $fnm(@aMuxTchStatFnms) {
   ProcMuxTchStatFile(\$fnm, \@cluInfo, \@CcBwnd, $fsnLatency);
   #$sfId1st=GetFileNameSuffix(\$fnm);
#     GetClipcastFlowStatsFromMuxTchStat(
#            \$fnm, $sfId1st,
#            \@CcFlowFldIdx,
#            \@CcBwnd,
#            $fsnLatency-1,   # Max Spill-over dur
#            \@CcFlowStat
#            );
}

#==================================================================
# SUB PROCEDURES
# ==================================================================
sub PrintUsage {
   print "Usage: $0 -rtv <num_video_ch> -cc <num_clipcast_ch> -ipdc <num_ipdc_ch> -l <fsn_latency> [-f MuxTchStatFiles]\n";
}

sub   ProcMuxTchStatFile#(\$fnm, \@cluInfo, \@CcWnd, $fsnLatency)
{
   my ($rFnm, $raCluInfo, $raCcWnd, $fsnLat)=(shift, shift, shift, shift);

   my ($ii, @CcFlowFldIdx);
   for($ii=0; $ii< $raCluInfo->[$CLU_NUMCC]; $ii++){
      push(@CcFlowFldIdx, 2+$raCluInfo->[$CLU_NUMRTV]*$RTR_NUM_FLD+
                         $NRTFR_NUM_FLD*$ii
           );
   }
#    for($ii=0; $ii< $raCluInfo->[$CLU_NUMIPDC]; $ii++){
#       push(@IpdcFlowFldIdx, 2+$raCluInfo->[$CLU_NUMRTV]*$RTR_NUM_FLD+
#                            $NRTFR_NUM_FLD*($raCluInfo->[$CLU_NUMCC]+$ii)
#            );
#    }

   my ($sfStart, $numSf, @CcImpWnd, @rawStatArr);

   # find the 1st SF and duration of the stat logs
   ($sfStart, $numSf) = GetMuxTchStatTimeInfo($rFnm);

   # make the Clipcast Impact Window for the log duration
   my $tmAdj= MakeCcImpactWnd(  # the returned time is the reference time (the last hour start time)
               $sfStart, $numSf, $raCcWnd, \@CcImpWnd, $fsnLat
               );

   $tmAdj = $sfStart - $tmAdj;   # relative time for the first SF

   # find the first delimary time that is applicable to the log duration
    my (@curDelimTmInfo, $curDelimTm, @nxtDelimTmInfo);
    #     DelimTimeInfo has two fields:
    #       [0]: window index
    #       [1]: delim time type: 0=start time; 1=end time
    $curDelimTm=FindFirstDelimTime($tmAdj,
                                   \@CcImpWnd,
                                   \@curDelimTmInfo);
    if($curDelimTm<0){  # there is no CcImpact window within the period
       $curDelimTm=$numSf+$tmAdj;
       @curDelimTmInfo=(-1, 0);
    }
    my ($fh, $line, $ra, $tm, @tmpArr, $cntProcSf);
    if(!open($fh,"<$$rFnm")){
       print "ERROR: FAILED to open file $$rFnm\n";   return;
    }

    while($line=<$fh>){
       chomp($line);
       $ra=[split(/\s+/,$line)];
       $tm=$ra->[$MTSL_IDX_SF]+$tmAdj;  #the SF ID in the MuxTch Stat should be continuous
       if($tm < $curDelimTm ){
          push(@rawStatArr, $ra);
       }else{
          # processing the period
          if($curDelimTmInfo[1]==0){
          #-------------------------------------------------------------
          # current period is not impacted by clipcast
             ProcMuxTchStatWndWithoutClipcast(\@rawStatArr, $sfStart, $raCluInfo);
             if( $#rawStatArr > $fsnLat-$MEDPRIO_TRIGGER_MARGIN ){
                # the last $fsnLat-$MEDPRIO_TRIGGER_MARGIN SFs should be within
                # the broadcast window of the next clip. KEEP them.
                @tmpArr=@rawStatArr[$#rawStatArr-($fsnLat-$MEDPRIO_TRIGGER_MARGIN)+1..
                                      $#rawStatArr];
                @rawStatArr=@tmpArr;  undef(@tmpArr);
             } #else{ # all the SFs should be kept}

          }else{
          #-------------------------------------------------------------
          # current period is impacted by clipcast
             $cntProcSf=ProcMuxTchStatWndWithClipcast(
                              \@rawStatArr, $sfStart,
                              $raCluInfo, \@CcFlowFldIdx, $fsnLat,
                              $CcImpWnd[ $curDelimTmInfo[$DTI_WNDIDX] ]->[$CIWI_BWND]
                              );
             # keep the SFs at the end that don't have clipcast spill-over traffic.
             @tmpArr=@rawStatArr[$cntProcSf..$#rawStatArr];
             @rawStatArr=@tmpArr;  undef(@tmpArr);
          }

          push(@rawStatArr, $ra);

          # start a new period with left-over data from previous period
          $curDelimTm=NextDelimTime(\@CcImpWnd, \@curDelimTmInfo, \@nxtDelimTmInfo);
          if($curDelimTm<0){  # there is no CcImpact window left in the period
             $curDelimTm=$numSf+$tmAdj;
             @curDelimTmInfo=(-1, 0);
          }else{
             @curDelimTmInfo=@nxtDelimTmInfo;
          }
       }
    }
    close($fh);
}

sub ProcMuxTchStatWndWithClipcast #(\@statArr, $sfBase, $raCluInfo,
                                  # \@CcFlowFldIdx, $fsnLat, $bcastWnd)
# ARGUMENTS:
# ----------------
# \@CcFlowFldIdx:  ref to an array: each element in the array specifying
#                  the index of the first field for the clipcast flow in
#                  the MuxTchStat line. It is assumed to be sorted for efficiency.
# RETURN:
# ----------------
#  the number of processed MuxTch stat lines
{
   my ($raStatArr, $sfBase, $raCluInfo, $raCcFlowFldIdx, $fsnLat, $bcastWnd)=
      (shift, shift, shift,shift, shift, shift);
   my (@lstNzCcSf, $sf, $cc, $actCcFlowIdx, $raFld, $kk, $sf,
       @ccStatArr, $fldIdx, $fldIdx2, $fldIdx3, @ccStat, $numProcLine);

   #print "$#{$raStatArr} SFs impacted by clipcast: bcastWnd=$bcastWnd\n";
   #print "--------------------------------------------------------------\n";
   # find the active clipcast flow & the last SF in which
   $sf=0;
   foreach $raFld ( @{$raStatArr} ){
      for($cc=0; $cc<=$#{$raCcFlowFldIdx}; $cc++){
         $fldIdx=$raCcFlowFldIdx->[$cc];
         push( @{$ccStatArr[$cc]},
               [ @{$raFld}[$fldIdx..$fldIdx+$NRTFR_NUM_FLD-1] ]);
         if( $raFld->[$fldIdx+$NRTFR_IDX_GRNRATE_MED]+
             $raFld->[$fldIdx+$NRTFR_IDX_GRNRATE_LOW] >0
           ){
            $lstNzCcSf[$cc]=$sf;
         }
      }
      $sf++;
   }
   # count the number of active flows (should be 1)
   $cc=0;
   foreach (@lstNzCcSf) {
      if( defined($_) ){   $cc++;}
   }

   if($cc==1){ # one active clipcast flow
      $actCcFlowIdx=0;
      foreach (@lstNzCcSf) {
         if( defined($_) ){
            # $actCcFlowIdx is index of the active clipcast flow
            $numProcLine = $_ + 1; # number of processed stat lines

#             print "--------------------------------\n";
#             $kk=0;
#             foreach (@{$ccStatArr[$actCcFlowIdx]}) {
#                if( $kk> $lstNzCcSf[$actCcFlowIdx] ){ last;}
#                print join(" ",@{$_})."\n";
#                $kk++;
#             }

            # Summary of clipcast stat
#             if(ProcCcFlowMuxStat($raStatArr, $raCcFlowFldIdx->[$actCcFlowIdx],
#                               $bcastWnd, \@ccStat)>0){
#                printf "%4d  %7.4f  %7.4f\n",
#                    $bcastWnd,
#                    $ccStat[$CCSTAT_SPILLOVERPCT],
#                    $ccStat[$CCSTAT_MEDPCT];
#             }

            # print out the raw data
            print "StartSF:$sfBase, NumRTV:$raCluInfo->[$CLU_NUMRTV], ".
                  "NumClipcast:1, NumIpdc:$raCluInfo->[$CLU_NUMIPDC], ".
                  "BcastWnd:$bcastWnd\n";
            $fldIdx=2+$raCluInfo->[$CLU_NUMRTV]*$RTR_NUM_FLD-1;
            $fldIdx2=$fldIdx+1+ $raCluInfo->[$CLU_NUMCC]*$NRTFR_NUM_FLD;
            $fldIdx3=$fldIdx2 + $raCluInfo->[$CLU_NUMIPDC]*$NRTFR_NUM_FLD-1;
            for($sf=0; $sf<$numProcLine; $sf++){
               print join(",",@{$raStatArr->[$sf]}[0..$fldIdx]).",".
                     join(",",@{$raStatArr->[$sf]}[$raCcFlowFldIdx->[$actCcFlowIdx]..
                                                   $raCcFlowFldIdx->[$actCcFlowIdx]+$NRTFR_NUM_FLD-1
                                                  ]
                          ).",".
                     join(",",@{$raStatArr->[$sf]}[$fldIdx2..$fldIdx3])."\n";
            }

            return $numProcLine;
         }
         $actCcFlowIdx++;
      }
   }elsif( $cc>1 ){
      print "ERROR: more than 1 clipcast flows on at the same time\n"; exit(-1);
   }elsif($cc<=0){
      print "ERROR: no clipcast flows on within the bcast window at ".
            eval($raStatArr->[0][$MTSL_IDX_SF]+$sfBase)." ($bcastWnd sec)\n";
      return 0;
   }
}

sub ProcMuxTchStatWndWithoutClipcast #(\@rawStatArr, $sfBase, $raCluInfo)
{
   my ($raStatArr, $sfBase, $raCluInfo)=(shift, shift, shift);

   my ($fldIdx, $fldIdx2, $fldIdx3);
   # print out the raw data
   print "StartSF:$sfBase, NumRTV:$raCluInfo->[$CLU_NUMRTV], ".
         "NumClipcast:0, NumIpdc:$raCluInfo->[$CLU_NUMIPDC]\n";
   # RT video & IPDC stats
   $fldIdx=2+$raCluInfo->[$CLU_NUMRTV]*$RTR_NUM_FLD-1;
   $fldIdx2=$fldIdx+1+ $raCluInfo->[$CLU_NUMCC]*$NRTFR_NUM_FLD;
   $fldIdx3=$fldIdx2+$raCluInfo->[$CLU_NUMIPDC]*$NRTFR_NUM_FLD-1;
   foreach (@{$raStatArr}){
      print join(",",@{$_}[0..$fldIdx]).",".
            join(",",@{$_}[$fldIdx2..$fldIdx3])."\n";
   }
}

sub CalcRtvKpi #(\@rawStatArr, $numRtvCh)
{
   my ($raStatArr, $numRtvCh)=(shift, shift);
}

sub ProcCcFlowMuxStat #(\@statArr, $idxFld0, $bwDur, \@ccStat)
# ARGUMENTS:
#  Spill-over percentage
#  % data tx at medium priority
# RETURN:
#  number of SFs in which the clipcast flow is active
{
   my ($raStatArr, $idxFld0, $bwDur, $raCcStat)=
      (shift, shift, shift, shift);

   my ($raFld, $sf, $cntActSf, $grnRate,$sum, $sumMed, $sumSpillOver);
   $sf=0; $cntActSf=0; $sum=0; $sumMed=0; $sumSpillOver=0;
   foreach $raFld (@{$raStatArr}) {
      $grnRate= $raFld->[$idxFld0+$NRTFR_IDX_GRNRATE_MED]+
                $raFld->[$idxFld0+$NRTFR_IDX_GRNRATE_LOW];
      $sum+=$grnRate; $sumMed+=$raFld->[$idxFld0+$NRTFR_IDX_GRNRATE_MED];
      $sf++;
      if( $sf > $bwDur){
         $sumSpillOver+=$grnRate;
      }
      if( $grnRate > 0 ){
         $cntActSf++;
      }
   }
   if( $sum>0 ){
      $raCcStat->[$CCSTAT_SPILLOVERPCT]= $sumSpillOver/$sum;
      $raCcStat->[$CCSTAT_MEDPCT]= $sumMed/$sum;
   }

   return   $cntActSf;
}

sub FindFirstDelimTime #($tm, \@delimTmArray, \@delimTmInfo)
# DelimTimeInfo has two fields:
#   [0]: window index
#   [1]: delim time type; 0=start time; 1=end time
# Return:
#  the first delimit time
#  -1 if reaching end
{
   my ($tm, $raDelimTm, $raDelimTmInfo)=
      (shift, shift, shift);

   my (@nextDelimTmInfo, $delimTm);
   @{$raDelimTmInfo}=(0,0);
   $delimTm = $raDelimTm->[0][0];
   while ( $tm > $delimTm ) {
      $delimTm=NextDelimTime($raDelimTm,$raDelimTmInfo, \@nextDelimTmInfo);
      @{$raDelimTmInfo}=@nextDelimTmInfo;
      if($delimTm<0){   last;}
   }
   return $delimTm;
}

sub NextDelimTime #(\@delimTm, \@curDelimTmInfo, \@nxtDelimTimInfo )
# DelimTimeInfo has two fields:
#   [0]: window index
#   [1]: delim time type: 0=start time; 1=end time
# Delimnary time types:
#   0: start time
#   1: end time
# RETURN:
#   next delim time: NOTE: -1 if reaching end
{
   if( $_[1]->[1]==0){
      $_[2]->[0] =$_[1]->[0];  # same window index
      $_[2]->[1] =1; # change delim time type

      return $_[0]->[$_[2]->[0]][1];
   }else{
      $_[2]->[0] =$_[1]->[0]+1;  # next window index
      $_[2]->[1] =0; # change delim time type

      if( $_[2]->[0] <= $#{$_[0]}){
         return $_[0]->[$_[2]->[0]][0];
      }else{
         return -1;
      }
   }
}

sub MakeCcImpactWnd #($sfStart, $numSf, \@CcWnd, \@CcImpactWnd, $fsnLatency)
# each entry in @CcImpactWnd is an array of three items:
#  [0]: impact start time
#  [1]: impact end time
#  [2]: broadcast window duration
#RETURN:
#
{
   my ($sfStart, $numSf, $raCcWnd, $raImpWnd, $fsnLat)=
      (shift, shift, shift, shift, shift);

   my ($tmRef, $numHr, $hh, $cc);
   $tmRef = LastHourStartPriorToGpsTime($sfStart);
   $numHr=ceil(($numSf+$sfStart-$tmRef)/3600);

   for($hh=0; $hh<$numHr; $hh++){
      for($cc=0; $cc<=$#{$raCcWnd}; $cc++){
         push(@{$raImpWnd},[$raCcWnd->[$cc][0]+$hh*3600 + $fsnLat-$MEDPRIO_TRIGGER_MARGIN,
                            $raCcWnd->[$cc][1]+$hh*3600 + $fsnLat,
                            $raCcWnd->[$cc][1] - $raCcWnd->[$cc][0] +1 # Broadcast Wnd size
                            ]
             );
      }
   }
   return  $tmRef;
}

sub   GetMuxTchStatTimeInfo #(\$fnm)
{
   my $rFnm =shift;
   my ($sfStart, $rawOut);

   $sfStart=GetFileNameSuffix($rFnm);
   $rawOut=`wc -l $$rFnm`;
   $rawOut=~/(\d+)/; ;

   return ($sfStart, $1);
}

sub  GetClipcastFlowStatsFromMuxTchStat
#ARGUMENTS:
#(
# \$fnmMuxTchStat: reference MuxTchStat file name. A MuxTchStat file has a
#                  MuxTchStat line for each SF
# $sfidFirst     : the SF id corresponding to the first MuxTchStat line
# \@CcFlowFldIdx:  ref to an array: each element in the array specifying
#                  the index of the first field for the clipcast flow in
#                  the MuxTchStat line. It is assumed to be sorted for efficiency.
# \@CcBwnd:        ref to an array of clipcast broadcast windows. It is a 2-D
#                  array. Bwnd is specified as start_time and end_time in seconds
#                  relative to the hour start.
# $maxSpillOver,
# \@CcFlowStat
#)
# RETURN:
#   number of processed Cc downloads if succeed
#   < 0: if fails
#
# LIMITATION:
#  - Clipcast broadcast windows have a hourly repeating pattern
#  - Clipcast broadcast windows don't span hour boundary
#  - assume there is no leap second within the period the MuxTchStat corresponds to
{
   my ($rFnm, $sfId1st, $raCcfFldIdx, $raCcBwnd, $maxSpillOver, $raCcFlowStat);
   $rFnm=shift; $sfId1st=shift; $raCcfFldIdx=shift;
   $raCcBwnd=shift; $maxSpillOver=shift; $raCcFlowStat=shift;

   #foreach (@{$raCcBwnd}) { print join(" ",@{$_})."\n";}
   #print join("  ", @{$raCcfFldIdx})."\n";   return -1;

   my ($fh, @wd, $prevHlt, $prevRelSfId, $hlt, $relSfId, $wndIdx,
       $stopTm, $fidx, @aCcLines, @ccStat);
   if(!open($fh,"<$$rFnm")){
      print "FAILED to open file $$rFnm\n";
      return   -1;
   }
   # get the hour relative time of the first SF
   $prevRelSfId = 0; $prevHlt=ConvGpsTimeToHrt($sfId1st);

   # For simplicity, skip the initial MuxTchStat lines that are within any broadcast window
   # as we don't have a full window worth of data.
   while(<$fh>){
      chomp; @wd=split(/\s+/);
      # get HLT of the current line
      $hlt= $prevHlt + ($wd[$MTSL_IDX_SF]-$prevRelSfId);
      while($hlt>3600){ $hlt-=3600;}
      $prevHlt=$hlt; $prevRelSfId = $wd[$MTSL_IDX_SF];

      if(FindCurrentCcBwnd($hlt, $raCcBwnd)<0){
         goto  FIND_NEXT_CCBWND;
      }
   }

   while(<$fh>){
      chomp; @wd=split(/\s+/);
      # get HLT of the current line
      $hlt= $prevHlt + ($wd[$MTSL_IDX_SF]-$prevRelSfId);
      while($hlt>3600){ $hlt-=3600;}
      $prevHlt=$hlt; $prevRelSfId = $wd[$MTSL_IDX_SF];

      # add optimization in the future: if current time is close to
      # the begining of a broadcast window
FIND_NEXT_CCBWND:
      $wndIdx=FindNextCcBwnd($hlt, $raCcBwnd);

      #print "$hlt -> [$raCcBwnd->[$wndIdx][$BWND_STARTIME], ".
      #               "$raCcBwnd->[$wndIdx][$BWND_ENDTIME]]\n";

      # find and processing MuxTchStat lines within the current broadcast
      # window and its spill-over duration
      # NOTE: Stop Time is the first SF after Bwnd+spill-over period
      $stopTm = $raCcBwnd->[$wndIdx][$BWND_ENDTIME]+$maxSpillOver;

      #print "Stop time: $stopTm\n";

      undef(@aCcLines);
      while(<$fh>){
         chomp; @wd=split(/\s+/);
         # get HLT of the current line
         $hlt= $prevHlt + ($wd[$MTSL_IDX_SF]-$prevRelSfId);
         while($hlt>3600){ $hlt-=3600;}
         # remember the reference point
         $prevHlt=$hlt; $prevRelSfId = $wd[$MTSL_IDX_SF];

         if( $hlt==$stopTm ){ # NOTE: don't use >= due to modulo
            # first line outside the broadcast window

            # process the period with clipcast on, also detect which tails lines
            # don't have clipcast transmission

            last;
         }
         if( $hlt>=$raCcBwnd->[$wndIdx][$BWND_STARTIME] &&
             $hlt<$stopTm  #NOTE: the 2nd condition
                           # is necessary due to modulo 3600
            ){
            # within the broadcast window + spillover
             for($fidx=0; $fidx<=$#{$raCcfFldIdx}; $fidx++){
                push(@{$aCcLines[$fidx]},
                     [@wd[$raCcfFldIdx->[$fidx]..
                          $raCcfFldIdx->[$fidx]+$NRTFR_NUM_FLD-1
                         ]
                     ]);

#                print join(" ",@wd[$raCcfFldIdx->[$fidx]..
#                                   $raCcfFldIdx->[$fidx]+$NRTFR_NUM_FLD-1])
#                      ." | ";
             }
#             print "\n";
         }
         #else lines before the broadcast window
      }

      # finish processing a broadcast window
      # NOTE: the current line is the line after the previous broadcast window
      #       + spill-over. But if we assume  the inter-wnd gap is > spill-over+1,
      #       the current line and the line following it should not be in
      #       any broadcast window. So it's OK not to process it.

      for($fidx=0; $fidx<=$#{$raCcfFldIdx}; $fidx++){
         if( ProcCcFlowMuxStat( $aCcLines[$fidx],
                  $raCcBwnd->[$wndIdx][$BWND_ENDTIME]-
                  $raCcBwnd->[$wndIdx][$BWND_STARTIME]+1,
                  \@ccStat)>0 ){
            #foreach ( @{$aCcLines[$fidx]}) { print join(" ",@{$_})."\n";}
            printf "%4d  %7.4f  %7.4f\n",
                   $raCcBwnd->[$wndIdx][$BWND_ENDTIME]-$raCcBwnd->[$wndIdx][$BWND_STARTIME]+1,
                   $ccStat[$CCSTAT_SPILLOVERPCT],
                   $ccStat[$CCSTAT_MEDPCT];
         }
      }

   }

   close($fh);
}

# sub ProcCcFlowMuxStat #(\@statLine, $bwDur, \@ccStat)
# # ARGUMENTS:
# #  Spill-over percentage
# #  % data tx at medium priority
# # RETURN:
# #  number of SFs in which the clipcast flow is active
# {
#    my ($raStatArr, $bwDur, $raCcStat);
#    $raStatArr=shift; $bwDur=shift; $raCcStat=shift;
#
#    my ($raFld, $sf, $cntActSf, $grnRate,$sum, $sumMed, $sumSpillOver);
#    $sf=0; $cntActSf=0; $sum=0; $sumMed=0; $sumSpillOver=0;
#    foreach $raFld (@{$raStatArr}) {
#       $grnRate= $raFld->[$NRTFR_IDX_GRNRATE_MED]+
#                 $raFld->[$NRTFR_IDX_GRNRATE_LOW];
#       $sum+=$grnRate; $sumMed+=$raFld->[$NRTFR_IDX_GRNRATE_MED];
#       $sf++;
#       if( $sf > $bwDur){
#          $sumSpillOver+=$grnRate;
#       }
#       if( $grnRate > 0 ){
#          $cntActSf++;
#       }
#    }
#    if( $sum>0 ){
#       $raCcStat->[$CCSTAT_SPILLOVERPCT]= $sumSpillOver/$sum;
#       $raCcStat->[$CCSTAT_MEDPCT]= $sumMed/$sum;
#    }
#
#    return   $cntActSf;
# }

sub LastHourStartPriorToGpsTime #($tm)
# return the last hour start time that is prior to the inputted GPS time
{
   my $dateTm=ConvGpsTimeToUTC($_[0]);
   if( $dateTm=~/(\w+)\s+(\d+)\s+(\d+):\d+:\d+\s+(\d+)/ ){
      # "Sat Jul 28 01:55:35 2007";
      return ConvUTCToGpsTime(\"$1 $2, $4 $3:00:00 GMT");
   }
   return -1;
}
sub ConvGpsTimeToHrt #($tm)
# Hrt = Hour Relative time
# RETURN:
#  [0, 3600) if successful
#  <0 if failure
{
   my $dateTm=ConvGpsTimeToUTC($_[0]);
   if( $dateTm=~/\d+:(\d+):(\d+)/ ){
      # "Nov 28, 2006 	20:03:02.365 GMT";
      return $1*60+$2;
   }
   return -1;
}
sub ConvCcBwndFormat #(\@CcBwnd)
{
   my $raBwnd=shift;
   my $ra;

   foreach $ra ( @{$raBwnd} ) {
      if( $ra->[$BWND_STARTIME] =~ /(\d+):(\d+)/ ){
         $ra->[$BWND_STARTIME] = $1 * 60 + $2;
         $ra->[$BWND_ENDTIME] += ($ra->[$BWND_STARTIME]-1);
      }
   }
}
sub FindNextCcBwnd #($curTm, \@CcBwnd)
# DESCRIPTION:
#  find the next broadcast window not covering the $curTm
# ARGUMENT:
#  $curTm: the current time in second relative to the hour start
#  \@CcBwnd:        ref to an array of clipcast broadcast windows. It is a 2-D
#                  array. Bwnd is specified as start_time and end_time in seconds
#                  relative to the hour start.
# RETURN:
#  index to the Bwnd entry in @CcBwnd
#
# LIMITATION:
#  - Broadcast windows in @CcBwnd is sorted in ascending order
{
   my ($tm, $raBwnd, $ra, $ii);
   $tm=shift; $raBwnd=shift;

   $ii=0;
   foreach $ra( @{$raBwnd} ) {
      if($ra->[$BWND_STARTIME]>$tm){
         return $ii;
      }
      $ii++;
   }
   return 0;
}

sub FindCurrentCcBwnd #($curTm, \@CcBwnd)
## DESCRIPTION:
#  find the current broadcast window covering the $curTm
# ARGUMENT:
#  $curTm: the current time in second relative to the hour start
#  \@CcBwnd:  ref to an array of clipcast broadcast windows. It is a 2-D
#             array. Bwnd is specified as start_time and end_time in seconds
#             relative to the hour start.
# RETURN:
#  index to the Bwnd entry in @CcBwnd if successful
#  -1  if failure
{
   my ($tm, $raBwnd, $ra, $ii);
   $tm=shift; $raBwnd=shift;

   $ii=0;
   foreach $ra( @{$raBwnd} ) {
      if($ra->[$BWND_STARTIME]<=$tm && $tm <= $ra->[$BWND_ENDTIME]){
         return $ii;
      }
      $ii++;
   }
   return -1;
}

sub GetFileNameSuffix #(\$fnm)
# File name convention:
#  the suffix of the file name is the SF Id
# RETURN:
#  "" if no suffix found
{
   if( ${$_[0]}=~/\.(\w+)\s*$/){
      return   $1;
   }
   return "";
}

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

sub ConvGpsTimeToUTC #( $gpsTime)
#Example $utc
# "Nov 16, 2006 06:59:02 GMT";
# "Nov 28, 2006 	20:03:02.365 GMT";
{

	return scalar gmtime($_[0]+$secsGpsUnix -$LEAP_SECONDS);
}

sub ConvUTCToGpsTime #( \$utc)
#Example $utc
# "Nov 16, 2006 06:59:02 GMT";
# "Nov 28 2006 	20:03:02.365 GMT";
{
	if(${$_[0]} =~ m{(\w+)\s+	# $1: Month
						  (\d+)(?:\s*,\s*|\s+) # $2: Day
						  (\d+)\s+	# $3: Year
						  (\d+):(\d+):(\d+) # $4 $5 $6
							}x){
      #print "$1 $2 $3 $4 $5 $6\n";
		return	timegm($6, $5, $4,
							 $2, $monthToMonthId{uc($1)},
							 $3
						 )-$secsGpsUnix +$LEAP_SECONDS;
	}else{
		return -1;
	}
#	return UnixDate(ParseDate(${$_[0]}),"%s")- $secsGpsUnix +$LEAP_SECONDS;
}




