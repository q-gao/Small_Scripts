#!/usr/bin/perl
#

if($#ARGV<0){
	print "Usage: $0 <Flow_Id>\n";
	exit(-1);
}

$flowId = shift(@ARGV);

while( $ln=<>){
	if($ln=~/\sSF\((\d+)\)/){
		$sf = $1;
	}elsif($ln=~/\sFlowId\($flowId\)/){
		if($ln=~/\((\d+)\/(\d+)\/(\d+)\)/){
			if($1>0){
				print "$sf $1 $2 $3\n";
			}
		}
	}
}

