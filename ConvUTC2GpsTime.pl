#!/usr/bin/perl

use Time::Local;

if($#ARGV<0){
	print	"Usage:ConvUTCToGpsTime <utc_time>\n";
	print "  UTC time format: \"Nov 16,2006 06:59:02 GMT\"\n";
	exit(-1);
}

$utc = shift(@ARGV);

InitUTCToGpsTimeConverter();

print ConvUTCToGpsTime(\$utc);	print "\n";

#-------------------------------------------------------------------------
# Global variable for UTC to GPS time conversion
our $LEAP_SECONDS = 14;
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

