#!/usr/bin/perl

use Time::Local;

if($#ARGV<0){
	print	"Usage:ConvGpsTimeToUTC <gps_time>\n";
	exit(-1);
}
$gpstm = eval(shift(@ARGV));

InitUTCToGpsTimeConverter();

print ConvGpsTimeToUTC($gpstm);	print "\n";

#-------------------------------------------------------------------------
# Global variable for UTC to GPS time conversion
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

