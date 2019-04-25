#!/usr/bin/perl
# USAGE: DiffFileNamesInFolders.pl <file_name_pattern> <folder_1> <folder_2> [<folder_3> ...]
#
# Print out the names of the files that are not in ALL the folders in the following
# format (the example below shows a.csv is present in folder 1 but not folder 2):
#  1 0 a.csv


use strict;
use File::Basename;

my $numFolder = $#ARGV;
if ( $numFolder < 2 ) {
   print
"USAGE: DiffFileNamesInFolders.pl <file_name_pattern> <folder_1> <folder_2> [<folder_3> ...]\n";
   exit(-1);
}

my @aFolders = @ARGV[ 1 .. $#ARGV ];
my %hFilePresence;
for ( my $fi = 0 ; $fi <= $#aFolders ; $fi++ ) {
   UpdateFilePresence( \%hFilePresence, \$ARGV[0], \@aFolders, $fi );
}

foreach my $f ( keys(%hFilePresence) ) {
   my ( $c, $i );
   $c = 0;
   for ( $i = 0 ; $i < $numFolder ; $i++ ) {
      $c += $hFilePresence{$f}[$i];
   }
   if ( $c != $numFolder ) {    # the file doesn't exist in ALL the folders
      print join( " ", @{ $hFilePresence{$f} } ), " $f\n";
   }
}

#============================================================
sub UpdateFilePresence #(\$hFilePresence, \$fileNamePattern, \@aFolders, $curFolderIdx)
{
   my ( $rhFilePresence, $rFileNamePattern, $raFolders, $curFolderIdx ) = @_;

   my @files = `find $raFolders->[$curFolderIdx] -name "$$rFileNamePattern"`;
   my $numFolders = $#{$raFolders} + 1;
   foreach my $f (@files) {
      chomp($f);
      my $baseName = basename($f);

      if ( !exists( $rhFilePresence->{$baseName} ) ) {
         $rhFilePresence->{$baseName} =
           [ (0) x $numFolders ];    #multiplier for annonymous array

      }
      $rhFilePresence->{$baseName}[$curFolderIdx] = 1;
   }
}

