#!/usr/bin/perl
use strict;

my @fontNames = `convert -list Font | grep Font`;

my $picHghtPixel = 1020;

my $txtHghtPixel = 30;
my $txtWidPixel = 375;
my $numFonts = GetNumFonts( \@fontNames);

my $numRow = int($picHghtPixel / $txtHghtPixel);

my $picWidPixel = int($numFonts / $numRow);
if( $numFonts % $numRow != 0 ) {
   $picWidPixel ++;
}

$picWidPixel *= $txtWidPixel;

my $cmd = "convert -size ${picWidPixel}x$picHghtPixel xc:white -draw \"font-size 24 fill black ";
my $x = 0; my $y = $txtHghtPixel;
foreach my $f (@fontNames) {
   chomp($f);
   if($f =~ /Font:\s*(.+)/) {
      my $fontName = $1;
      if( $fontName =~ /ghostscript_font_path/ ) {
          next; 
      }
      
      $cmd .= " font $fontName text $x,$y \'$fontName\'";
      $y += $txtHghtPixel;
      if( $y >= $picHghtPixel ) {
         $y = $txtHghtPixel;
         $x += $txtWidPixel;
      }           
   }
}

#$cmd .= "\" gif:- | display gif:-";
$cmd .= "\" FontList.jpg";
system($cmd);

print "\nNum Fonts: $numFonts\n";
#================================================
sub GetNumFonts #(\@fontNames)
{
   my ($raFn) = @_;
   my $c = 0;
   foreach my $f (@{$raFn} ) {
      if($f =~ /Font:\s*(.+)/ && !($f =~ /ghostscript_font_path/)) {         
         $c++;           
      }      
   }
   return $c;
}