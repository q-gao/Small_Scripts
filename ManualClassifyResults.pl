#!/usr/bin/perl
#
# This simple script displays images in a directory one at a time, ask for the user's
# opinion about it, and move the images to the folder corresponding to the opinion
#
# Usage:
#  ManualClassifyResults.pl <img_root_dir> <image_file_name_pattern> <opinion_1> [<more_opinions>]
#   where <opinion> = "<Letter> <save_dir>"
#
# Example:
#  ManualClassifyResults.pl VGA_HVGA "*.jpg" 1 VGA_Better 2 Same 3 HVGA_Better
#

use strict;
use File::Basename;
use threads
  ; # Perl needs to be compiled to support threading. see https://wiki.bc.net/atl-conf/pages/viewpage.action?pageId=20548191
use threads::shared;

my $programDir = dirname($0);
require "$programDir/com/utility.pl";

if ( $#ARGV < 3 || !( $#ARGV % 2 ) ) {
   print
"Usage: ManualClassifyResults.pl <img_root_dir> <image_file_name_pattern> <opinion_1> [<more_opinions>]\n";
   print "where <opinion> = <Letter> <save_dir>\n";
   exit(-1);
}

# parse arguments
my ( $imgDir, $fileNamePattern ) = @ARGV[ 0, 1 ];
my ( @userOptions, @saveDirs );
my $promptString = "";
for ( my $ii = 2 ; $ii <= $#ARGV ; $ii += 2 ) {
   push( @userOptions, $ARGV[$ii] );
   push( @saveDirs,    $ARGV[ $ii + 1 ] );
   $promptString .= "$ARGV[$ii] - (" . $ARGV[ $ii + 1 ] . ")\t";

   if ( !( -e $ARGV[ $ii + 1 ] ) ) {
      print "Directory " . $ARGV[ $ii + 1 ] . " doesn't exist => create it\n";
      system( "mkdir " . $ARGV[ $ii + 1 ] );
   }
}

# display images
my @imgFiles = `find $imgDir -name "$fileNamePattern"`;
foreach my $imgf (@imgFiles) {
   chomp($imgf);
   my $cmd = "display $imgf";
   print
"\n-------------------------------------------------------------\n$cmd\n------------------------------------------------------\n\n";
   my $t = threads->new( \&Thread_ExecCommand, $cmd );

   while (1) {
      my $in = PromptUser($promptString);
      my $sel;

      for ( $sel = 0 ; $sel <= $#userOptions ; $sel++ ) {
         if ( $in eq $userOptions[$sel] ) {
            last;
         }
      }

      if ( $sel <= $#userOptions ) {
         my @pids = GetProcessID("display");
         foreach (@pids) {
            system("kill -KILL $_ >/dev/null");
         }

         # move the image file
         $cmd = "mv $imgf $saveDirs[$sel]";
         print "$cmd\n";
         system($cmd);

         last;
      }
      else {
         print "Wrong choice! Please try it again.\n";
      }

   }
}

