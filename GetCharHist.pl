#!/usr/bin/perl

while(<>){
 if(/tag="(.)"/) {
  $charHist{$1}++;
 }
}

foreach (sort {$a cmp $b} keys(%charHist)) {
 print "$_,$charHist{$_}\n";
}
