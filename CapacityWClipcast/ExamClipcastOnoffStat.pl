#!/usr/bin/perl
#
#

use strict;

# Define the structure of the stat line
our (
	$FLD_SF,
	$FLD_MUXTHRPT,

	#----------- RT Flow Record
	$FLD_RTFR_START,
  )
  = ( 0, 1, 2 );

our (
	$RTFR_MUXREQRATE,         #requested rate
	$RTFR_MUXGRNRATE,         # granted rate
	$RTFR_MUXACTRATE,         # actual rate
	$RTFR_RANKIDX_PICKED,     # rank index picked by MUX due to re-encoding
	$RTFR_RANK_PICKED,
	$RTFR_PRERATE,            # pre-reencoding data rate (without CSF)
	$RTFR_PRECPSNR,           # pre-reencoding Conv PSNR
	$RTFR_PREWPSNR,           # pre-reencoding Wt. PSNR
	$RTFR_PRENPSNR,           # pre-reencoding Norm PSNR
	$RTFR_POSRQ_RATE,         # post-requantization data rate (without CSF)
	$RTFR_POSRQ_CPSNR,        # post-requantization Conv PSNR
	$RTFR_POSRQ_WPSNR,        # post-requantization Wt. PSNR
	$RTFR_POSRQ_NPSNR,        # post-requantization Norm PSNR
	$RTFR_IFRM_SIZE,
	$RTFR_CSF_SIZE,
	$RTFR_NUM_REFRM,          # number of reference frames (I & P)
	$RTFR_NUM_NONREFRM,       #number of non-reference frames (B)
	$RTFR_NUM_REFRMDROP,      # number of reference frames (I & P) dropped by TCH
	$RTFR_NUM_NONREFRMDROP,   #number of non-reference frames (B) dropped by TCH
	$RTFR_REQRATE,            # requested rate (including CSF)
	$RTFR_GRNRATE,            # granted rate (including CSF)
	$RTFR_POSTDROPRATE,       # actual sent rate (including CSF)
	$RTFR_CNTCLASS,           # Content class
	$RTFR_DQP_IP,             # Delta QP for I & P frames
	$RTFR_DQP_B,

	#-----------
	$NUM_RTFR_FLD
  )
  = (
		0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13,
		14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
  );

our (
		$NRTFR_REQRATE_MED,       # requested rate at medium priority
		$NRTFR_REQRATE_LOW,       # requested rate at low priority
		$NRTFR_GRNRATE_MED,       # granted rate at medium priority
		$NRTFR_GRNRATE_LOW,       # granted rate at low priority
		                          # ---
		$NUM_NRTFR_FLD
  )
  = ( 0, 1, 2, 3, 4 );

our ( $KPI_NUMSF, $KPI_REENC_PROB, $KPI_RRUC_RATIO ) = ( 0, 1, 2 );

#StartSF:870570162, NumRTV:16, NumClipcast:1, NumIpdc:16, BcastWnd:153
my (
	  $procState, $newSeg,     $line,        $numRtv,
	  $numCc,     $numIpdc,    $bcastDur,    @arrStat,
	  @prdMed,    %hPrdMedCnt, %hPrdMedLoad, $sf,
	  $intvl,     @rtmedRate,  @kpi,         $ff,
	  $prdStat,   $prdDur,     %kpiResult,   %histRtvReqNoCc,
	  %histRtvReqWithCc,
);

$procState = 0;
$newSeg    = 0;
while ( $line = <> ) {
	chomp($line);

	# a new segment starts or not
	# ---------------------------------------------
	if ( $line =~ m{NumRTV:(\d+),\s*NumClipcast:(\d+),\s*NumIpdc:(\d+)}x ) {
		( $numRtv, $numCc, $numIpdc ) = ( $1, $2, $3 );
		$newSeg = 1;
		if ( $numCc > 0 && $line =~ /BcastWnd:(\d+)/ ) {
			$bcastDur = $1;
		}
	} else {
		$newSeg = 0;
	}

	# state machine
	#----------------------------------
	if ( $procState == 0 ) {    # no segment started:
		                         #skip all lines until seg start
		if ($newSeg) {
			if ( $numCc > 0 ) { $procState = 2; }
			else { $procState = 1; }
		}
	} elsif ( $procState == 1 ) {    # segment without clipcast
		                              #skip all lines until seg start
		if ($newSeg) {
			UpdateRtvReqRateHist( \@arrStat, $numRtv, \%histRtvReqNoCc );

			# process the data
			$intvl = 25;
			for ( $sf = 0 ; $sf <= $#arrStat - $intvl ; $sf += $intvl ) {
				push( @prdMed, [ $sf, $sf + $intvl - 1 ] );
			}
			GetRtvMedRateInCcMedPeriods( \@arrStat, $numRtv, $numIpdc, \@prdMed );
			foreach (@prdMed) {
				push( @rtmedRate, $_->[2] );
			}

			#release memory
			undef(@prdMed);
			undef(@arrStat);

			# state change
			if ( $numCc > 0 ) { $procState = 2; }
			else { $procState = 1; }
		} else {    # collect data for the segment
			push( @arrStat, [ split( /,/, $line ) ] );
		}
	} else {    # segment with clipcast
		if ($newSeg) {    # end of a previous segment
			               # process the data
			UpdateRtvReqRateHist( \@arrStat, $numRtv, \%histRtvReqWithCc );
			GetCcMedPeriods( \@arrStat, $numRtv, \@prdMed );
			GetRtvMedRateInCcMedPeriods(       \@arrStat,         $numRtv,
												  $numCc + $numIpdc, \@prdMed );

			# Eacn entry in prdMed (period medium priority)
			#  start_time, end_time, load, loadMedPriority
			foreach $prdStat (@prdMed) {

				# load for the period <=0 <=> not enough data
				if ( $prdStat->[2] <= 0 ) { next; }

				$prdDur = $prdStat->[1] - $prdStat->[0] + 1;
				$hPrdMedCnt{$prdDur}++;
				$hPrdMedLoad{$prdDur} += $prdStat->[2];

				# calculate KPI
				undef(@kpi);

				if (
					  CalcRtvKpi(
									  \@arrStat, $prdStat->[0], $prdStat->[1],
									  $numRtv,   \@kpi
					  ) == 0
				  )
				{    #SUCCESS
					    # print out results
					    # segmend duration, segmend load

#              printf "%d,%6.0f,%6.0f", $prdDur,$prdStat->[2],$prdStat->[3];
#              for($ff=0; $ff<$numRtv; $ff++){
#                 printf ",%6.4f,%6.4f", $kpi[$ff]->[$KPI_REENC_PROB],$kpi[$ff]->[$KPI_RRUC_RATIO];
#              }
#              print "\n";
					$kpiResult{ $prdStat->[2] } =
					  [ $prdDur, $prdStat->[2], $prdStat->[3] ];
					for ( $ff = 0 ; $ff < $numRtv ; $ff++ ) {
						push(
								@{ $kpiResult{ $prdStat->[2] } },
								$kpi[$ff]->[$KPI_REENC_PROB]
						);
						push(
								@{ $kpiResult{ $prdStat->[2] } },
								$kpi[$ff]->[$KPI_RRUC_RATIO]
						);
					}
				}
			}

			#release memory
			undef(@prdMed);			undef(@arrStat);

			# state change
			if ( $numCc > 0 ) { $procState = 2; }
			else { $procState = 1; }
		} else {    # collect data for the segment
			push( @arrStat, [ split( /,/, $line ) ] );
		}
	}
}

foreach ( sort { $a <=> $b } keys(%kpiResult) ) {
	printf "%d %6.0f %6.0f", $kpiResult{$_}->[0], $kpiResult{$_}->[1],
	  $kpiResult{$_}->[2];
	for ( $ff = 3 ; $ff <= $#{ $kpiResult{$_} } ; $ff++ ) {
		printf " %6.4f", $kpiResult{$_}->[$ff];
	}
	printf "\n";
}

# RTV req rate hist with clipcast
printf "RTV Request Rate Histogram with Clipcast\n";
foreach ( sort { $a <=> $b } keys(%histRtvReqWithCc) ) {
	printf "%6d %d\n", $_, $histRtvReqWithCc{$_};
}

# RTV req rate hist without clipcast
printf "RTV Request Rate Histogram without Clipcast\n";
foreach ( sort { $a <=> $b } keys(%histRtvReqNoCc) ) {
	printf "%6d %d\n", $_, $histRtvReqNoCc{$_};
}

#print "Medium Clipcast Periods\n";
#foreach (sort {$a<=>$b} keys(%hPrdMedCnt) ) {
#   printf "%5d,%5d,%10.2f\n", $_, $hPrdMedCnt{$_},
#                              $hPrdMedLoad{$_}/$hPrdMedCnt{$_};
#}
#
#print "No clipcast\n";
#foreach (sort {$a<=>$b} @rtmedRate ) {
#   print "$_\n";
#}

########################################################################
# Functions
########################################################################
sub GetCcMedPeriods    #(\@stat, $numRtv, \@prdCcMed)
{
	my ( $raStat, $numRtv, $raPrdMed ) = ( shift, shift, shift );

	my ( $bCcMed, $numSf, $ccFldBeg, $sf, $sfCcMedBeg );
	$bCcMed = 0;
	$numSf  = $#{$raStat} + 1;

	for ( $sf = 0 ; $sf < $numSf ; $sf++ ) {
		$ccFldBeg = $FLD_RTFR_START + $NUM_RTFR_FLD * $numRtv;
		if ( $bCcMed == 0 ) {    # Clipcast NOT at Medium Priority yet
			if ( $raStat->[$sf][ $ccFldBeg + $NRTFR_GRNRATE_MED ] > 0 ) {
				$sfCcMedBeg = $sf;
				$bCcMed     = 1;
			}
		} else {
			if ( $raStat->[$sf][ $ccFldBeg + $NRTFR_GRNRATE_MED ] <= 0 ) {
				push( @{$raPrdMed}, [ $sfCcMedBeg, $sf - 1 ] );
				$bCcMed = 0;
			}
		}
	}

	if ($bCcMed) {    # the last CcMed period
		push( @{$raPrdMed}, [ $sfCcMedBeg, $numSf - 1 ] );
		$bCcMed = 0;
	}
}

sub UpdateRtvReqRateHist    #(\@stat, $numRtv,\%hist)
{
	my ( $raStat, $numRtv, $rhHist ) = ( shift, shift, shift );

	my ( $numSf, $fld, $sf, $flow, $sumRtReqRate );

	$numSf = $#{$raStat} + 1;

	for ( $sf = 0 ; $sf < $numSf ; $sf++ ) {
		$fld          = $FLD_RTFR_START + $RTFR_MUXREQRATE;
		$sumRtReqRate = 0;
		for ( $flow = 0 ; $flow < $numRtv ; $flow++ ) {
			if ( $raStat->[$sf][$fld] < 0 ) {
				goto _UpdateRtvReqRateHist_NextSf;
			}
			$sumRtReqRate += $raStat->[$sf][$fld];
			$fld          += $NUM_RTFR_FLD;
		}
		$rhHist->{$sumRtReqRate}++;
	 _UpdateRtvReqRateHist_NextSf:
	}
}

sub GetRtvMedRateInCcMedPeriods    #(\@stat, $numRtv, $numNrt,\@prdCcMed)

  # Get sum of RT granted rates and granted medium priority rates for
  # clipcast and IPDC (NRT)
  #
{
	my ( $raStat, $numRtv, $numNrt, $raPrdMed ) = ( shift, shift, shift, shift );

	my ( $pp, $sumRtMedRate, $sumMedRate, $sf, $flow, $fld, $dur, $missData );

	# for each period
	#--------------------------------------------------
	for ( $pp = 0 ; $pp <= $#{$raPrdMed} ; $pp++ ) {
		$sumRtMedRate = 0;
		$sumMedRate   = 0;
		$missData     = 0;

		# all the SFs in a period
		#---------------------------------------------
		for ( $sf = $raPrdMed->[$pp][0] ; $sf <= $raPrdMed->[$pp][1] ; $sf++ ) {

			# RT flow
			$fld = $FLD_RTFR_START + $RTFR_MUXREQRATE;
			for ( $flow = 0 ; $flow < $numRtv ; $flow++ ) {
				if ( $raStat->[$sf][$fld] < 0 ) {
					$missData = 1;
					goto _GetRtvMedRateInCcMedPeriods_PeriodEnd;
				}
				$sumRtMedRate += $raStat->[$sf][$fld];
				$fld          += $NUM_RTFR_FLD;
			}

			#NRT flow
			$fld = $FLD_RTFR_START + $NUM_RTFR_FLD * $numRtv + $NRTFR_REQRATE_MED;
			for ( $flow = 0 ; $flow < $numNrt ; $flow++ ) {
				if ( $raStat->[$sf][$fld] < 0 ) {
					$missData = 1;
					goto _GetRtvMedRateInCcMedPeriods_PeriodEnd;
				}
				$sumRtMedRate += $raStat->[$sf][$fld];
				$sumMedRate   += $raStat->[$sf][$fld];
				$fld          += $NUM_NRTFR_FLD;
			}
		}
	 _GetRtvMedRateInCcMedPeriods_PeriodEnd:
		if ($missData) {
			push( @{ $raPrdMed->[$pp] }, -1 );
			push( @{ $raPrdMed->[$pp] }, -1 );
		} else {
			$dur = $raPrdMed->[$pp][1] - $raPrdMed->[$pp][0] + 1;
			$sumRtMedRate /= $dur;
			$sumMedRate   /= $dur;
			push( @{ $raPrdMed->[$pp] }, $sumRtMedRate );
			push( @{ $raPrdMed->[$pp] }, $sumMedRate );
		}
	}
}

sub CalcRtvKpi    #(\@stat, $sfStart, $sfEnd, $numRtv, \@kpi)

  # RETURN:
  #  0  : Success
  #  -1 : not enough valid data in @stat to calculate the KPI
{
	my ( $raStat, $sfStart, $sfEnd, $numRtv, $raKpi ) =
	  ( shift, shift, shift, shift, shift );

	my ( $sf, $fld, $ff, $rr, $rrduc, $rtv );

	$rtv = 0;

	# NOTE: -1 value indicates the corresponding stat is missing
	#       in the log.
	#
	# each Super-frame
	for ( $sf = $sfStart ; $sf <= $sfEnd ; $sf++ ) {

		#each flow
		for ( $ff = 0, $fld = $FLD_RTFR_START ;
				$ff < $numRtv ;
				$ff++, $fld += $NUM_RTFR_FLD )
		{

			if (    $raStat->[$sf][ $fld + $RTFR_MUXREQRATE ] < 0
				  || $raStat->[$sf][ $fld + $RTFR_MUXGRNRATE ] < 0 )
			{
				print "LOG ERROR: miss MUX_REQRATE || MUX_GRNRATE for flow $ff\n";
				return -1;
			}

			if ( $raStat->[$sf][ $fld + $RTFR_MUXREQRATE ] >
				  $raStat->[$sf][ $fld + $RTFR_MUXGRNRATE ] )
			{

				# re-encoding prob
				$raKpi->[$ff][$KPI_REENC_PROB]++;

				# rate reduction
				if (    $raStat->[$sf][ $fld + $RTFR_REQRATE ] < 0
					  || $raStat->[$sf][ $fld + $RTFR_POSTDROPRATE ] < 0 )
				{
					print
"LOG ERROR: miss TCH_REQRATE || TCH_POSTDROPRATE for flow $ff\n";
					return -1;
				}

				#NOTE: all rates and sizes from TCH logs are in bit per sec.
				$rr    = $raStat->[$sf][ $fld + $RTFR_REQRATE ];
				$rrduc = $rr - $raStat->[$sf][ $fld + $RTFR_POSTDROPRATE ];

	# consider CSF
	#             if($raStat->[$sf][$fld+$RTFR_CSF_SIZE]<0 && # no CSF
	#                $raStat->[$sf][$fld+$RTFR_IFRM_SIZE]<=0) # no I frame
	#             {  print "LOG ERROR: miss CSF_SIZE for flow $ff\n"; return -1;}

				if ( $raStat->[$sf][ $fld + $RTFR_CSF_SIZE ] > 0 ) {
					$rrduc /= ( $rr - $raStat->[$sf][ $fld + $RTFR_CSF_SIZE ] );
				} else {
					$rrduc /= $rr;
				}

				$raKpi->[$ff][$KPI_RRUC_RATIO] += $rrduc;
			}
		}
	}
	for ( $ff = 0 ; $ff < $numRtv ; $ff++ ) {
		$raKpi->[$ff][$KPI_NUMSF] = $sfEnd - $sfStart + 1;

		# rate reduction is conditioned on occurance of re-encoding
		if ( $raKpi->[$ff][$KPI_REENC_PROB] > 0 ) {
			$raKpi->[$ff][$KPI_RRUC_RATIO] /= $raKpi->[$ff][$KPI_REENC_PROB];
		} else {
			$raKpi->[$ff][$KPI_RRUC_RATIO] = 0;
		}

		$raKpi->[$ff][$KPI_REENC_PROB] /= $raKpi->[$ff][$KPI_NUMSF];
	}
	return $rtv;
}
