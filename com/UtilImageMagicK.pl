#
# utilities based on ImageMagicK
#

#=============================================================
sub  GetImageResolution #(\$fileName, \@resolution)
# INPUT:
#   $resolution[0] = width
#   $resolution[1] = height
# RETURN:
#    non-zero:  SUCCESS
#    0:         FAILURE
{
  my ($rImgFile, $rRes) = (shift, shift);

  my $imgInfo = `identify $$rImgFile`;
  if($imgInfo =~ /\s(\d+)x(\d+)\s/) {
    $rRes->[0] = $1;
    $rRes->[1] = $2;
    return 1;
  } else {
    $rRes->[0] = 0;
    $rRes->[1] = 0;
    return 0;
  }
}

1;
