#!/usr/bin/perl

if($#ARGV<1){
  print "Usage: $0 <start SF> <num of SFs>\n";
  exit(-1);
}

$startSf=shift(@ARGV);
$numSf = shift(@ARGV);
$endSf = $startSf + $numSf -1;

while($ln=<>){
 if($ln=~/SF\((\d+)\)/){
   $sf = $1;
   if($sf > $endSf){
        last;
   }
   if($sf>=$startSf){
		print $ln;
	}
 }elsif(defined($sf) && $sf >= $startSf){
  print $ln;
 }
}


