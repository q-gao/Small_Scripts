#!/usr/bin/perl
#


if($#ARGV < 0){
	exit(-1);
}

$lsout=`ls -l $ARGV[0]`;

chomp($lsout);

if($lsout =~ /\s+->\s+([\/\w\s\.-]+)/){
	$path = $1;

	$HOME=`echo $HOME`;
	# replace ~ with $HOME
	$path =~ s/~/$HOME/;

	# replace "\ " with " "
	$path=~ s/\\\s+/ /g;

	# replace with drive letter
	$path =~ s/^\/cygdrive\/(\w+)\//$1:\\/g;

	# replace / with \
	$path =~ s/\//\\/g;

	# if there is space in the name

	#$path=~ s/\s+/\\ /g;		
	#print $path;

	if($path=~/\s/){
		print "\"$path\"";
	}else{
		print $path;
	}

}
