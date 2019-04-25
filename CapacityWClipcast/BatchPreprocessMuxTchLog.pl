#!/usr/bin/perl
#
#  <MUX_log_file> <TCH_log_dir> <Lineup_Name>

use strict;

our $PRGM_CHKFLOWS     = "../../Script_by_Qiang/GetFlowRatesFromFlmLog.pl";
our $PRGM_PREPROCESS   = "../../Script_by_Qiang/PreprocessMuxTchLogs.pl ";
our $PRGM_SHOWMUXLOGTM = "./ShowMuxLogTimes.pl";

# Arguments
#-----------------------------------------
our $TEST_MODE = 0;
our @numToMonth = (
						  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
						  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
);

my ( $chLineUp, $fnmFlowIdCfg, $fnmMuxTchLogList, $tkn );
while ( defined( $tkn = shift(@ARGV) ) ) {
	if    ( $tkn eq "-test" ) { $TEST_MODE        = 1; }
	elsif ( $tkn eq "-c" )    { $chLineUp         = shift(@ARGV); }
	elsif ( $tkn eq "-f" )    { $fnmFlowIdCfg     = shift(@ARGV); }
	elsif ( $tkn eq "-m" )    { $fnmMuxTchLogList = shift(@ARGV); }
}

if (    !defined($chLineUp)
	  || !defined($fnmFlowIdCfg)
	  || !defined($fnmMuxTchLogList) )
{
	print "ERROR: Some mandatory arguments are missed\n";
	print
"Usage:$0 [-test] -c <Channel_LineUp_Name> -f <FlowId_Cfg_File> -m <MUX_TCH_Log_List_File>\n";
	exit(-3);
}

#-----------------------------------------------------
my ( @arMuxTchLogFnm, $fh, $ll, @cmdOutput, @wd );

# read list of MUX and TCH log files
#-------------------------------------
open( $fh, "<$fnmMuxTchLogList" )
  or die "FAILED to open file $fnmMuxTchLogList\n";
while (<$fh>) {
	@wd = split(/\s+/);
	if ( $#wd >= 1 ) {	# skip empty or invalid line
		push( @arMuxTchLogFnm, [ split(/\s+/) ] );
	}
}
close($fh);

if ( $#arMuxTchLogFnm < 0 ) {
	print "No MUX & TCH log files are listed in $fnmMuxTchLogList\n";
	exit(-2);
}

# find the MUX log file name
print "\nINFO: prepare MUX logs\n";
print "-----------------------------------------------\n";

for ( $ll = 0 ; $ll <= $#arMuxTchLogFnm ; $ll++ ) {
	@cmdOutput = `ls $arMuxTchLogFnm[$ll][0]/*RTV_mux.log*`;
	if ( $#cmdOutput < 0 ) {
		print "ERROR: no MUX log file in $arMuxTchLogFnm[$ll][0]";
		next;
	} elsif ( $#cmdOutput > 0 ) {
		print "ERROR: more than one MUX log files in $arMuxTchLogFnm[$ll][0]";
		next;
	}
	$arMuxTchLogFnm[$ll][0] = $cmdOutput[0];
	chomp( $arMuxTchLogFnm[$ll][0] );

	if ( $arMuxTchLogFnm[$ll][0] =~ /(.+)\.gz$/ ) {
		MySystem( \"gunzip -v $arMuxTchLogFnm[$ll][0]" );
		$arMuxTchLogFnm[$ll][0] = $1;
	}
}

# remove nonexistent channels from the FlowIdCfg file
#-----------------------------------------------------
print "\nINFO: remove off channels from $fnmFlowIdCfg\n";
print "-----------------------------------------------\n";

my ( $cmd, $prgm, $arg, @flowStat, @flowOff );
$prgm = '@w=split(/\s+/);print "$w[4]\n";';    # get the video flow Ids
$cmd  =
"grep qvc $fnmFlowIdCfg | perl -ne '$prgm' | $PRGM_CHKFLOWS -n 600 -f $arMuxTchLogFnm[0][0]";
print "$cmd\n";
@flowStat = `$cmd`;
print join( "", @flowStat );

foreach (@flowStat) {
	if ( /FlowId/ || /flows\s+found/ ) { next; }
	@wd = split(/\s+/);

	# skip empty element
	for ( $ll = 0 ; $ll <= $#wd ; $ll++ ) {
		if ( $wd[$ll] ) { last; }
	}
	while ( $ll > 0 ) { shift(@wd), $ll--; }

	if ( $wd[0] =~ /^\d+$/ ) {

		#print join(" ",@wd)."\n";
		if ( $wd[2] <= 0.0 || $wd[2] =~ /--/ ) {
			push( @flowOff, $wd[0] );
		}
	}
}

print "\n\nThe following video flows were off:";
foreach (@flowOff) { print " $_"; }
print "\n";

my ( @lines, $ln, $foff );
open( $fh, "<$fnmFlowIdCfg" ) or die "ERROR: failed to open $fnmFlowIdCfg\n";
while (<$fh>) { push( @lines, $_ ); }
close($fh);

open( $fh, ">$fnmFlowIdCfg" )
  or die "ERROR: failed to open $fnmFlowIdCfg for writing\n";
foreach $ln (@lines) {
	foreach $foff (@flowOff) {
		if ( $ln =~ /\s+$foff\s+/ ) {
			goto SKIP_FLOW_OFF_LINE;
		}
	}
	print $fh $ln;
 SKIP_FLOW_OFF_LINE:
}
close($fh);

print "INFO: $#flowOff off video flows have been removed from $fnmFlowIdCfg\n";

# Get Active TCH name
#-----------------------------------------------------
print "\nINFO: Get active TCH names\n";
print "-----------------------------------------------------\n";
$prgm = '@w=split(/\s+/);print "$w[5]\n";';            # TCH name
$cmd  = "grep qvc $fnmFlowIdCfg | perl -ne '$prgm'";
my (@tchNames);
print "\n$cmd\n";
@tchNames = `$cmd`;
printf "INFO: the following %d TCHs are active:\n", $#tchNames + 1;
print "\t" . join( "\t", @tchNames ) . "\n";

# Process MUX & TCH logs
#---------------------------------
my ( @tchLogNames, $tch, $tmInfo, $gmtTm, $numSf );
for ( $ll = 0 ; $ll <= $#arMuxTchLogFnm ; $ll++ ) {
	print "\nINFO: unzip TCH logs\n";
	print "-----------------------------------------------\n";
	foreach $tch (@tchNames) {

		#NOTE: gunzip only processes files with gz suffix
		chomp($tch);
		$cmd = "gunzip -v $arMuxTchLogFnm[$ll][1]/$tch/mediaflo.log_*";
		MySystem( \$cmd );
	}

	$cmd = "$PRGM_SHOWMUXLOGTM $arMuxTchLogFnm[$ll][0]";
	print "\n$cmd\n";
	@cmdOutput = `$cmd`;
	foreach $tmInfo (@cmdOutput) {
		if ($tmInfo) {

			# preprocess MUX TCH logs
			#------------------------------------------
			print $tmInfo;
			chomp($tmInfo);
			$numSf = GrabTimeInfoFromShowMuxLogTimeOutput( \$tmInfo, \$gmtTm );
			if ( $numSf > 0 ) {
				$cmd =
				    "$PRGM_PREPROCESS \"$gmtTm\" $numSf "
				  . "$arMuxTchLogFnm[$ll][0] $arMuxTchLogFnm[$ll][1] "
				  . "$fnmFlowIdCfg MuxTchLog_$chLineUp";
				print "\nINFO: preprocess MUX & Tch logs\n";
				print "-----------------------------------------------\n";
				MySystem( \$cmd );
			} else {
				print "ERROR: wrong time info from $arMuxTchLogFnm[$ll][0]\n";
			}
			last;
		}
	}

	#zip TCH logs
	print "\nINFO: zip TCH logs\n";
	print "-----------------------------------------------\n";
	foreach $tch (@tchNames) {

		#NOTE: gunzip only processes files with gz suffix
		chomp($tch);
		$cmd = "gzip -v $arMuxTchLogFnm[$ll][1]/$tch/mediaflo.log_*";
		MySystem( \$cmd );
	}
}

#zip MUX logs
#------------------------------------
print "\nINFO: zip MUX logs\n";
print "-----------------------------------------------\n";
for ( $ll = 0 ; $ll <= $#arMuxTchLogFnm ; $ll++ ) {
	MySystem( \"gzip -v $arMuxTchLogFnm[$ll][0]" );
}

##########################################################################
sub MySystem    #(\$cmd)
{
	my $rCmd = shift;

	print "$$rCmd\n";
	if ( !$TEST_MODE ) {
		system($$rCmd);
	}
}

sub GrabTimeInfoFromShowMuxLogTimeOutput    #(\$tmInfo, \$gmtTm);

# ShowMuxLogTime's output:
# 20070915_0021_16RTV/16RTV_mux.log           09/15/2007-00:21:16.000  09/15/2007-08:21:15.000   873850892  873879691       28800
{
	my ( $rTmInfo, $rGmtTm ) = ( shift, shift );
	my @wd = split( /\s+/, $$rTmInfo );

	if ( $#wd < 5 ) { return -1; }

	if ( $wd[1] =~ /(\d+)\/(\d+)\/(\d+)-(\d+:\d+:\d+)/ ) {
		$$rGmtTm = "$numToMonth[$1-1] $2,$3 $4 GMT";
	} else {
		return -1;
	}

	return $wd[5];
}
