#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin $Script);
use lib "$Bin";
use SVG;
use FontSize;


my $str = 'hello, world, I love China';
my $family = "Arial";
my $size = 54;

my $figure = "me.svg";

my $font = FontSize->new();

my $width = $font->stringWidth($family,$size,$str);
my $height = $font->stringHeight($size);


my $svg = SVG->new('width',1000,'height',800);


$svg->text('x',100,'y',100,'stroke','red','font-family',$family,'font-size',$size,'-cdata',$str);

$svg->rect('x',100, 'y',100-$height,'width',$width,'height',$height,'stroke','green','fill','none');


open OUT,">$figure.t" || die "fail $figure.t";
print OUT $svg->xmlify();
close OUT;

`perl $Bin/buildInFont.pl $figure.t x $figure`;
`rm $figure.t`;


