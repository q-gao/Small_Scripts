#!/usr/bin/perl
# wls: ls accepting windows style path. It has the same options as ls

#print join(",",@ARGV)."\n\n";
# replace drive letter with cygdrive
foreach $path (@ARGV) {
   # replace drive letter to /cygdrive
   $path =~ s/(\w+):\\/\/cygdrive\/$1\//g;
   #replace '\' to '/';
   $path =~ s/\\/\//g;

   if($path =~/\s+/){
      $path="\"$path\"";
   }
}

$cmd="ls --color ".join(" ",@ARGV);
system($cmd);




