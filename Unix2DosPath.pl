#!/usr/bin/perl
#


if($#ARGV < 0){
	exit(-1);
}

$HOME=`echo $HOME`;

$path = shift(@ARGV);

# replace ~ with $HOME
$path =~ s/~/$HOME/;

## replace "\ " with " "
#$path=~ s/\\\s+/ /g;
# replace "\ " with "\\ "
$path=~ s/\\?\s+/\\\\ /g;


# replace with drive letter
$path =~ s/^\/cygdrive\/(\w+)\//$1:\\/g;

# replace / with \
$path =~ s/\//\\/g;

# if there is space in the name
#if($path=~/\s/){
#	print "\"$path\"";
#}else{
#	print $path;
#}
print $path;

