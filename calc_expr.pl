#!/usr/bin/perl

if( $#ARGV>= 0 ){
	print "  ";
	foreach(@ARGV){ print eval($_)."\t";}
	print "\n";
}else{
	# read expression from stdin
	print "> ";
	while($e=<>){
		if( $e eq "quit" || $e eq "exit" ){ last;}
		else{
			print "  ".eval($e)."\n> ";
		}
	}
}
