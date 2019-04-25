# Common utility function
#
use List::Util qw[min max];

#================================================================================
sub CalcBoundingRectangles    #(\@aorRects, $raBoundRect);

# COMMENTS:
#   Each rectangle is defined by an array:
#   [0]: x
#   [1]: y
#   [2]: width
#   [3]: height
#
# ARGUMENTS:
#   $raoaRects: reference to an array of references to arrays defining a rectangle
#   $raBoundRect: reference to an array defining a rectangle
#
{
   my ( $raoaRects, $raBoundRect ) = ( shift, shift );

   my ( $ii, @aoa );
   @aoa = ( [], [], [], [] );    # Array of Array

   # prepare data
   foreach my $r (@$raoaRects) {

      # x and y
      for ( $ii = 0 ; $ii < 2 ; $ii++ ) {
         push( @{ $aoa[$ii] }, $r->[$ii] );
      }

      # x+width and y+height
      for ( $ii = 2 ; $ii < 4 ; $ii++ ) {
         push( @{ $aoa[$ii] }, $r->[ $ii - 2 ] + $r->[$ii] );
      }
   }

   # find the bounding box by min and max
   #---------------------------------------------------
   # x and y
   for ( $ii = 0 ; $ii < 2 ; $ii++ ) {
      $raBoundRect->[$ii] = min( @{ $aoa[$ii] } );
   }

   # x+width and y+height
   for ( $ii = 2 ; $ii < 4 ; $ii++ ) {
      $raBoundRect->[$ii] = max( @{ $aoa[$ii] } );

      # then adjusted to width or height
      $raBoundRect->[$ii] -= $raBoundRect->[ $ii - 2 ];
   }
}

#================================================================================
sub CalcRectanglesIntersection    #(\@aorRects, $raRectIntersect);

# COMMENTS:
#   Each rectangle is defined by an array:
#   [0]: x
#   [1]: y
#   [2]: width
#   [3]: height
#
#   A rectangle with either width or height element <= 0 represents an empty rectangle
#
# ARGUMENTS:
#   $raoaRects: reference to an array of references to arrays defining a rectangle
#   $raRectIntersect: reference to an array defining a rectangle
#
#
{
   my ( $raoaRects, $raRectIntersect ) = ( shift, shift );

   my ( $ii, @aoa );
   @aoa = ( [], [], [], [] );    # Array of Array

   # prepare data
   foreach my $r (@$raoaRects) {

      # x and y
      for ( $ii = 0 ; $ii < 2 ; $ii++ ) {
         push( @{ $aoa[$ii] }, $r->[$ii] );
      }

      # x+width and y+height
      for ( $ii = 2 ; $ii < 4 ; $ii++ ) {
         push( @{ $aoa[$ii] }, $r->[ $ii - 2 ] + $r->[$ii] );
      }
   }

   # find the intersection by max and min
   #---------------------------------------------------
   # x and y
   for ( $ii = 0 ; $ii < 2 ; $ii++ ) {
      $raRectIntersect->[$ii] = max( @{ $aoa[$ii] } );
   }

   # x+width and y+height
   for ( $ii = 2 ; $ii < 4 ; $ii++ ) {
      $raRectIntersect->[$ii] = min( @{ $aoa[$ii] } );

      # then adjusted to width or height
      $raRectIntersect->[$ii] -= $raRectIntersect->[ $ii - 2 ];
   }
}

#========================================================================
sub PromptUser    # ($promptString,$defaultValue)
{

   #-------------------------------------------------------------------#
   #  two possible input arguments - $promptString, and $defaultValue  #
   #  make the input arguments local variables.                        #
   #-------------------------------------------------------------------#

   my ( $promptString, $defaultValue ) = @_;

   #-------------------------------------------------------------------#
   #  if there is a default value, use the first print statement; if   #
   #  no default is provided, print the second string.                 #
   #-------------------------------------------------------------------#

   if ($defaultValue) {
      print $promptString, "[", $defaultValue, "]: ";
   }
   else {
      print $promptString, ": ";
   }

   $| = 1;          # force a flush after our print
   $_ = <STDIN>;    # get the input from STDIN (presumably the keyboard)

   #------------------------------------------------------------------#
   # remove the newline character from the end of the input the user  #
   # gave us.                                                         #
   #------------------------------------------------------------------#

   chomp;

   #-----------------------------------------------------------------#
   #  if we had a $default value, and the user gave us input, then   #
   #  return the input; if we had a default, and they gave us no     #
   #  no input, return the $defaultValue.                            #
   #                                                                 #
   #  if we did not have a default value, then just return whatever  #
   #  the user gave us.  if they just hit the <enter> key,           #
   #  the calling routine will have to deal with that.               #
   #-----------------------------------------------------------------#

   if ("$defaultValue") {
      return $_ ? $_ : $defaultValue;    # return $_ if it has a value
   }
   else {
      return $_;
   }
}

#========================================================================
sub GetProcessID                         #($processName)
{
   my ($pname) = @_;

   my @psFilteredOut = `ps | grep $pname`;

   #DEBUG
   #print join("", @psFilteredOut);

   my @pids = ();
   foreach (@psFilteredOut) {
      chomp;
      if (/^\s*(\d+)/) {
         push( @pids, $1 );
      }
   }
   return @pids;
}

#========================================================================
sub Thread_ExecCommand    # ($cmd)
{
   my $cmd = shift;
   system($cmd);
}

#========================================================================
sub CreateDirIfNotExist    #(\$dir)

  # It creates a dir (e.g., "root/sub1/sub2") if it doesn't exists. It will
  # create the parent directories first if needed
{
   my ($rDir) = @_;

   my @aDirName = split( '/', $$rDir );

   CreateDirIfNotExist_ArrayFormat(\@aDirName);
}

#========================================================================
sub CreateDirIfNotExist_ArrayFormat    #(\@dirName)

  # It creates a dir (e.g., "root/sub1/sub2") if it doesn't exists. It will
  # create the parent directories first if needed
{
   my ($raDirName) = @_;

   if ( $#{$raDirName} < 0 ) { return; }
   
   my ( $curDir, $ii );
   if ( $raDirName->[0] eq "" ) {    # "/a/b/" will be split to ["","a", "b"]
      $curDir = "/";
      $ii     = 1;
   }
   else {
      $curDir = "";
      $ii     = 0;
   }
   
   for(; $ii <= $#{$raDirName} ; $ii++) {
      $curDir .= ($raDirName->[$ii]."/");
      if(!(-e $curDir)) {
         #print "mkdir $curDir\n";
         system("mkdir $curDir");
      }
   }
}

#================================================
sub GetDirDepth
# RETURN:
#   number of dir levels in a dir patt
{
   my @a = split('/', $_[0]);
   
   return $#a + 1;
}

1;      # needed!
