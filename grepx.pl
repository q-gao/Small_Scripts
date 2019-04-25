#!/usr/bin/perl
#
# Usage: MyGrep [-c <cc>] [-p <pp>] [-n <nn>] [-m] -e <reg_ex> [files]\n"
#			  <cc>: max number of matching lines displayed
# 			  <pp>: number of extra lines proceding the matching line
#			  <nn>: number of extra lines following the matching line
#           -m : mark the extra lines proceding or following the matching lines
#

$maxMatchLine = 4294967296; # max of 32 bit unsigned int
$numFollowline = 0;
$numPreline = 0;
$markerExLine="";

#print "$0\n";
if($#ARGV<1){
	PrintUsage();	exit(-1);
}

while(defined($tkn=shift(@ARGV))){
	if($tkn eq "-c"){
		$maxMatchLine=shift(@ARGV);
	}elsif($tkn eq "-p"){
		$numPreline=shift(@ARGV);
	}elsif($tkn eq "-n"){
		$numFollowline=shift(@ARGV);
	}elsif($tkn eq "-e"){
		$regexp=shift(@ARGV);
	}elsif($tkn eq "-m"){
      $markerExLine="  | ";
   }else{
		push(@inFiles, $tkn);
	}
}

if(!defined($regexp)){
	print "ERROR: no regular expression specified\n";
	PrintUsage(); exit(-2);
}

# Use of defined on aggregates (hashes and arrays) is deprecated. It used to report 
#whether memory for that aggregate had ever been allocated. This behavior may disappear
# in future versions of Perl. You should instead use a simple test for size:
if ( ! @inFiles ){ #if(!defined(@inFiles)){
	push(@inFiles,"-");
}

#print "$maxMatchLine $numFollowline $regexp\n";

foreach $curFnm (@inFiles){
	if(!open(INFILE,"<$curFnm")){
		print "\nFAILED to open file $curFnm\n\n";
		next;
	}

	$numMatchLine = 0;
	while($line=<INFILE>){
		if($line=~/$regexp/){
         # found a matching line
			$numMatchLine++;
         # print out preceding lines
         foreach (@preLines) {
            print "$markerExLine$_";
         }
         undef(@preLines);
         # print out matching line
			print $line;
         # print out following lines
			for($ii=0; $ii < $numFollowline; $ii++){
				if(defined($line=<INFILE>)){
					print "$markerExLine$line";
				}else{
					last;
				}
			}

			if($numMatchLine >= $maxMatchLine){last;}
		}elsif($numPreline>0){  # need to print out preceding lines
         # not a matching line, added it to @preLines
         if($#preLines >= $numPreline-1){ shift(@preLines);}
         push(@preLines, $line);
      }
	}

	close(INFILE);
}

sub PrintUsage{
	print "Usage: MyGrep [-c <cc>] [-p <pp>] [-n <nn>] [-m] -e <reg_ex> [files]\n".
         "       <cc>: max number of matching lines displayed\n".
	      "       <pp>: number of extra lines preceding the matching line\n".
	      "       <nn>: number of extra lines following the matching line\n".
         "       -m  : mark the extra lines".
         "       <reg_ex>: perl style regular expression\n";
}
