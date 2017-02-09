#!/usr/bin/perl  -w

=head1 Name

bar_diagram.pl

=head1 Description

draw the bar diagram of SVG

=head1 Version

 Author: Wenbin Liu, liuwenbin@genomics.org.cn
 Version: 1.0,  Date: 2010-04-24
 Version: 2.0,  Date: 2010-11-27  Update: add option --sig_pos,dge,right,nosign,blank
 Version: 2.1,  Date: 2011-01-17  Update: add option --tranxy,preci
 Version: 2.2,  Date: 2011-02-10  Do some improve in the advice of Liang Xinming
 Version: 2.3,  Date: 2011-07-25  Update: add option -interval,stroke

=head1 Usage

 perl bar_diagram.pl  <infile>  [--Option --help] >out.svg
 infile             input file store the data to draw diagram
 --Option:
 1 about paper size
 --width <num>      the length of the x axis, default=400
 --height <num>     the length of the y axis, default=300
 --barw <num>       the width of a bar, failure when --width set
 --flank_y <num>    distance from y axis to edge of drawing paper, default=height/3
 --flank_x <num>    distance from x axis to edge of drawing paper, default=flank_y
 
 2 about symbol
 --nohead           the head 2rows not descirbe data, x-area date get from first rank
 --nosign           do not draw the symbol
 --table            infile in table form
 --ranks <str>      only show specify ranks when -table, ranks star from 0, default show all ranks
 --row <num>        max row the get at infile(head not concluded), default use all row.
 --symbol <str>     symbol text split by ',', default get form head info
 --size_sig <num>   figure symbol sign text font-size, default=0.05*height
 --sig_pos <str>    the position of the symbol star coordinate x,y, default auto
 --right            put the sign at the right of figure, or put at head
 --column <num>     the column number of symbol when symbol at head, default=2;
 
 3 about title and scale
 --h_title <str>    the head title, default no title
 --y_title <str>    the title of ylab, default no title
 --x_title <str>    the tilte of xlab, default no title
 --h_pos <str>      the middle position of the head title, default auto
 --size_ht <num>    the head title font-size, default=0.09*height
 --size_yt <num>    y-area title font-size, default=0.08*height
 --size_xt <num>    xlab title font-size, default = size_yt
 --size_ys <num>    y-area scale font-size, default=0.05*height
 --size_xs <num>    x-area text font-size, default=0.035*width
 --edge             put the x-area text at the edge of two group, default in middle
 --interval         to show x-area text interval
 --inter_num <num>  interval number, default=1
 --preci <num>      y-area scale precision option, select from 1..4, default=3
 --y_mun <str>      specified y-area scale unit,number, default not set
 
 4 about bar
 --style <1/2>      bar style: bars in a group 1 heap up, 2 abreast; default=1
 --tranxy           to exchange x-y area, but x y title will not change
 --blank <fig>      the space between two group, 1 is width of one bar, default=1
 --colors <str>     the colours of the bar fill, splited by ',', default auto
 --stroke <str>     colors for bar stroke, default equal to fill color
 --help             output help information to screen

=head1 Notice

 1 The from of infile to be: first line x-axis name group, second line graphic symbol,
   other line eatch data of the x-axis group turn to the symbol.
 2 The symbol could have blank in second line of infile must split by "\t" or ';'
 3 when --tranxy, width and height set will exchange
 4 When width and barw not set but budget barw < 10, than barw will set to be 10
 5 The out svgfile must end by suffix ".svg".

=head1 Example

 perl bar_diagram.pl   orthologs.statdate > out.svg

=cut

use strict;
use Getopt::Long;

my ($height,$width, $flank_x,$flank_y, $size_x,
    $size_xt, $size_scale, $size_sig, $tranxy,$size_yt,
    $ylab_title,$xlab_title, $style,$color,$sig_pos,
    $blank,$edge,$nosign, $column, $right,$h_title,
    $preci,$help,$h,$barw,$y_mun,$h_pos,$size_ht,$row,
    $nohead,$Symbol,$interval,$stroke,$inter_num,$table,
    $ranks,$grid
);
GetOptions(
           "height:i"   => \$height,
           "width:i"    => \$width,
           "flank_x:i"  => \$flank_x,
           "flank_y:i"  => \$flank_y,
           "barw:i"     => \$barw,
           "inter_num:i"=> \$inter_num,
           "nohead"		=> \$nohead,
           "symbol:s"	=> \$Symbol,
           "size_xs:f"  => \$size_x,
           "size_xt:f"  => \$size_xt,
           "size_yt:f"  => \$size_yt,
           "tranxy"     => \$tranxy,
           "preci:i"    => \$preci,
           "y_mun:s"	=> \$y_mun,
           "size_ys:f"  => \$size_scale,
           "size_sig:f" => \$size_sig,
           "y_title:s"  => \$ylab_title,
           "x_title:s"  => \$xlab_title,
           "style:i"    => \$style,
           "edge"       => \$edge,
           "interval"	=> \$interval,
           "colors:s"   => \$color,
           "stroke:s"   => \$stroke,
           "right"      => \$right,
           "nosign"     => \$nosign,
           "blank:f"    => \$blank,
           "column:i"   => \$column,
           "sig_pos:s"  => \$sig_pos,
           "h_pos:s"	=> \$h_pos,
           "size_ht:f"	=> \$size_ht,
           "h_title:s"	=> \$h_title,
           "help"       => \$help,
           "h"          => \$h,
           "table"      => \$table,
           "ranks:s"    => \$ranks,
           "row:i"      => \$row,
           "grid"       => \$grid
);
$help && (die `pod2text $0`);
if (@ARGV != 1 || $h)
{
    die "Name: bar_diagram.pl
Author: Wenbin Liu, liuwenbin\@genomics.org.cn
Version: 2.3,  Date: 2011-07-25
Usage: perl bar_diagram.pl  <infile>  [--Option --help] >out.svg
 <infile>          the file store the data in the diagram
 -nosign           do not draw the symbol
 -nohead           the head 2rows not descirbe data, x-area date get from first rank
 -table            infile in table form
 -symbol <str>     symbol text split by ',', default get form head info
 -sig_pos <str>    the symbol star area 'x,y', default auto
 -h_title <stre>   the head title, default no title
 -y_title <str>    the title of ylab, default no title
 -x_title <str>    the tilte of xlab, default no title
 -style <1/2>      bar sytle: bars in a group 1 heap up, 2 abreast; default=1
 -tranxy           to exchange x-y area, but x y title will not change
 -blank <fig>      the space between two group, 1 is width of one bar, default=1
 -colors <str>     the colours of the bar, split by ',', default auto
 -stroke <str>     colors for bar stroke, default equal to fill color
 -edge             put the x-area text at the edge of two group, default in middle
 -right            put the sign at the right of figure, or put at head
 -column <num>     the column number of symbol when symbol at head, default=2;
 -preci <num>      y-area scale precision option, select from 1..4, default=3
 -h                output brief help information to screen
Note: You can use --help to get detail help information\n";
}

#************************************************************#
#
#                          MAIN                              #
#
#************************************************************#
open IN, shift;
my @sel = $ranks ? split/,/,$ranks : ();
my (@x_group,@symbol,$sample_name);
if(!$nohead || $table){
	chomp(my $fline = <IN>);
	@x_group = ($fline=~/;/) ? (split/;/,$fline) : ($fline=~/\t/) ? (split/\t/,$fline) : (split/\s+/,$fline);
    if($table){
        $sample_name = shift @x_group;
        @symbol = @x_group;
        $ranks && (@symbol = @symbol[@sel]);
        @x_group = ();
        $nohead = 1;
    }else{
	    chomp(my $sline = <IN>);
	    ($sline =~ /\S/) ? (@symbol = split /;|\t/, $sline): ($nosign = 1);
    }
}
$Symbol && (@symbol = split/,/,$Symbol);
@symbol || ($nosign = 1);
my $tol_amin = 0;
$style ||= 1;
$inter_num ||= ($interval ? 2 : 1);
($inter_num > 1) && ($interval = 1);
($style eq "1" || $style eq "2") || die"Error: --style noly can be 1 or 2\n";
my @y_group;
my $max_y = 0;
my $del_lim = $nohead ? 2 : 1;
foreach (<IN>){
	/\d/ || next;
	chomp;
	my @l = split /\s+/;
    (@l < $del_lim) && next;
    ($l[-1] =~ /^\d/) || next;
	$tol_amin++;
	$nohead && (push @x_group,(shift @l));
    $ranks && (@l = @l[@sel]);
    push @y_group,[@l];
    $max_y =
    ($style == 1) ? max($max_y, sum(@l)) : max($max_y, @l);
    $row && ($tol_amin == $row) && last;
}
close IN;
$blank  ||= 1;
my $budget_bar_num = ((($style==2) ? @{$y_group[0]} : 1) + $blank) * $tol_amin;
($budget_bar_num > 50) && ($barw ||= 10);

use SVG;
##======        Global Variable       ======##
$width   ||= ($barw ? $barw*$budget_bar_num : $tranxy ? 300 : 450);
$height  ||= $tranxy ? 450 :300;
$flank_y ||= $height / 3;
$flank_x ||= $flank_y;
$tranxy && ($flank_x *= 1.2);
$size_scale ||= 0.03 * $height;    #################
$size_yt    ||= 0.04 * $height;
$size_ht		||= 0.08 * $height;
$size_x ||= $tranxy ? $size_scale : 0.03 * $width;  ###### The size of the x  axis title
if(!$tranxy){
	my $may_size_x = ($interval ? 1.5 : 2) * $width / (@x_group * longest_str(@x_group));
	($may_size_x < $size_x) && ($size_x = $may_size_x);
}
$size_xt    ||= $size_yt;
$size_sig   ||= 0.05 * $height;
$preci      ||= 3;
$tranxy && (($width,$height) = ($height,$width));
my $pwidth  = $width + $flank_x * 1.5;     # Calculate the width of the paper
my $pheight = $height + $flank_y * 1.6;    # Calculate the height of the paper
$right && ($pwidth += $flank_x);
my @colors =
  qw(darkblue cornflowerblue deeppink bisque white lightgreen lightblue green yellow orange black);
if($color){
	@colors = ((split/,/,$color),@colors);
}

#==

#
#=========================================================#
#                 Creat A New Bode                        #
#=========================================================#

##======   Creat A New drawing paper  ======##
my $w1 = "http://www.w3.org/2000/svg";
my $w2 = "http://www.w3.org/1999/xlink";
my $svg = SVG->new(width=> $pwidth,height=> $pheight,xmlns => $w1,"xmlns:xlink" => $w2);

#==

#=========================================================#
#                 Drawing The Bar graphs                  #
#=========================================================#

##=======   Draw  the X Y axis   =======##
##
my ($yvalue_min, $yvalue_number) = $y_mun ? (split/,/,$y_mun) : &axis($max_y, 0.95, $preci);
# Use &axis to caclutate the min value and the number of value that show in the y axis
# Caclutate the space the value in the y axis take in the paper,one number's length is likely to bo 7;
my $yalia_unit = ($tranxy ? $width : $height) / $yvalue_number;
my $ypolt_unit = $yalia_unit / $yvalue_min;    # The rate of distance in the y ordinate to the real while drawing
my $xpolt_unit = ($tranxy ? $height : $width) / $tol_amin;    # The min distance in the x ordinate while drawing
#my $x_axis_low = ($tranxy && $grid) ? $flank_y : $height + $flank_y;
#$svg->line('x1',$flank_x,'y1',$x_axis_low,'x2',$width + $flank_x,'y2',$x_axis_low,
#           'stroke','black','stroke-width', 2);    # x axis
##=======   Draw  the  Y axis   =======##
my $y_max = 0;
my ($ylab_x, $ylab_y, $ylab);
if ($tranxy){
    for (0 .. $yvalue_number)    {
        ($ylab_x, $ylab_y, $ylab) = ($flank_x + $yalia_unit * $_,$flank_y + $height + $size_scale,$_ * $yvalue_min);
#        ($grid && $_ == $yvalue_number) && next;
        $svg->text('x',$ylab_x, 'y',$ylab_y,'stroke','none','fill','black','-cdata',$ylab,'font-size', $size_scale,'font-family','Arial','text-anchor', 'middle');
        $svg->line('x1',$ylab_x,'y1',$flank_y + $height + $size_scale / 5,
                   'x2',$ylab_x,'y2',$flank_y + $height,'stroke','black','stroke-width', $_ ? 1 : 2);
        (!$_ || $_ == $yvalue_number) && next;
        $grid && $svg->line('x1',$ylab_x,'y1',$flank_y,'x2',$ylab_x,'y2',$flank_y + $height,
                'stroke','black','stroke-width', 1);
    }
}else{
    for (0 .. $yvalue_number){
        ($ylab_x, $ylab_y, $ylab) = ($flank_x - $size_scale / 3,$flank_y + $height - $yalia_unit * $_,$_ * $yvalue_min);
        $svg->text('x',$ylab_x,'y',$ylab_y + $size_scale / 3,'stroke','none','fill','black',
        '-cdata',$ylab,'font-size',$size_scale,'font-family','Arial','text-anchor','end');
        $svg->line('x1', $flank_x, 'y1', $ylab_y, 'x2',$flank_x - $size_scale / 5,'y2', $ylab_y, 'stroke', 'black', 'stroke-width', 2);
        ($y_max < length($ylab)) && ($y_max = length($ylab));
        (!$_ || $_ == $yvalue_number) && next;
        $grid && $svg->line('x1', $flank_x, 'y1', $ylab_y, 'x2',$flank_x+$width,'y2', $ylab_y,
                'stroke', 'black', 'stroke-width', 1);
    }
}
 my $yused_size = $size_scale * $y_max / 2;
##===== Draw the X Y axis title ======##
$xlab_title ||= 0;
$ylab_title ||= 0;
$tranxy && (($size_yt, $size_xt) = ($size_xt, $size_yt),
      $yused_size = longest_str(@x_group) * $size_x / 2 + $size_x / 2);
if ($xlab_title){
    my ($ttxx, $ttxy) = ($flank_x + $width / 2,$height +$flank_y + 2 * ($tranxy ? $size_scale : $size_x) +2 * $size_xt / 3);
    $svg->text('x',$ttxx,'y',$ttxy,'stroke','none','fill','black','-cdata',$xlab_title, 'font-size', $size_xt,'text-anchor', 'middle','font-family','Arial');
}
if ($ylab_title){
    my $g = $svg->group("transform" => "rotate(-90)");
    my ($ytitle_x, $ytitle_y) = ($flank_x - $size_yt - $yused_size,$flank_y + 0.5 * $height - $size_yt * length($ylab_title) / 4);
     # we put the center of the y-title at the y-axis Golden-Point
    ($ytitle_x, $ytitle_y) = (-$ytitle_y, $ytitle_x);
    $g->text('x',$ytitle_x,'y',$ytitle_y,'stroke','none', 'fill','black','-cdata',$ylab_title, 'font-size', $size_yt,'font-family','Arial','text-anchor', 'end');
}

##=======   darw the bar diagram  =======##
my $sym_num = @{$y_group[0]};
my $split_unit_x = ($style == 1) ? $xpolt_unit / (1 + $blank)
  : $xpolt_unit / ($sym_num + $blank);
my $x1 = ($tranxy ? $flank_y : $flank_x) + $blank * $split_unit_x / 2;
my ($y_0, $x_0);
$y_0 = $tranxy ? $flank_x : ($height + $flank_y);
my ($xtitle_x, $xtitle_y) = $tranxy ? 
($flank_x - $size_x / 2, ($edge ? $flank_y : $flank_y + 0.5 * $xpolt_unit))
  : ($edge ? $flank_x : ($flank_x + 0.5 * $xpolt_unit),$flank_y + $height + 1.25*$size_x);
my ($texanchor, $texx, $texy, $texh, $texw) = $tranxy ? ('end', 'y', 'x', 'width', 'height')
  : ('middle', 'x', 'y', 'height', 'width');

foreach my $i (0 .. $tol_amin - 1){
    $x_0 = $x1;
    my $xline = ($tranxy ? $flank_y : $flank_x) + $xpolt_unit * ($i + 1);
    $tranxy ? $svg->line('x1', $flank_x, 'y1', $xline, 'x2', $flank_x - $size_x / 5,
                   'y2', $xline, 'stroke', 'black', 'stroke-width', 2)
      : $svg->line('x1', $xline, 'y1', $y_0, 'x2', $xline, 'y2',
                   $y_0 + $size_x / 5,'stroke', 'black', 'stroke-width', 2);
    my $xalia_title;
    if($interval && !($i % $inter_num)){
    	$xalia_title = $x_group[$i/$inter_num];
    	$svg->text('x',$xtitle_x,'y',$xtitle_y + ($tranxy ? $size_x / 3 : 0),'stroke','none', 'fill','black','-cdata',
    	$xalia_title,'font-size',$size_x,'font-family','Arial','text-anchor', $texanchor);
    }elsif(!$interval){
    	$xalia_title = $x_group[$i];
    	$svg->text('x',$xtitle_x,'y',$xtitle_y + ($tranxy ? $size_x / 3 : 0),'stroke','none', 'fill','black','-cdata',
    	$xalia_title,'font-size',$size_x,'font-family','Arial','text-anchor', $texanchor);
    }
    my $y1 = $y_0;
    foreach my $j (0 .. $sym_num - 1){
        my $yh = $ypolt_unit * (${$y_group[$i]}[$j] || 0);
        my $stroke_color = ($stroke || $colors[$j]);
        $tranxy || ($y1 = ($style == 1) ? $y1 - $yh : ($y_0 - $yh));
        $svg->rect($texx,$x1,$texy, $y1,$texw,$split_unit_x,$texh,$yh,'stroke', $stroke_color, 'fill', $colors[$j]);
        ($style == 1) || ($x1 += $split_unit_x);
        $tranxy && ($style == 1) && ($y1 += $yh);
    }
    $x1 = $x_0 + $xpolt_unit;
    $tranxy ? ($xtitle_y += $xpolt_unit) : ($xtitle_x += $xpolt_unit);
}
$tranxy && $svg->line('x1', $flank_x, 'y1', $flank_y, 'x2', $flank_x - +$size_x / 5,
                'y2', $flank_y, 'stroke', 'black', 'stroke-width', 2);
$edge  && ($xlab_title = "$x_group[-1]",
      $svg->text('x',$xtitle_x,'y',$xtitle_y + ($tranxy ? $size_x / 3 : 0),'font-family','Arial','stroke','none',
                 'fill','black','-cdata',$xlab_title,'font-size',$size_x,'text-anchor', $texanchor));
#($tranxy && $grid) || $svg->line('x1',$flank_x,'y1',$height + $flank_y,'x2',$width + $flank_x,'y2',$height + $flank_y,'stroke','black','stroke-width', 2);    # x axis
$svg->line('x1',$flank_x,'y1',$height + $flank_y,'x2',$width + $flank_x,'y2',$height + $flank_y,'stroke','black','stroke-width', 2);    # x axis
$svg->line('x1',$flank_x,'y1',$flank_y,'x2',$flank_x,'y2',$height + $flank_y + ($tranxy ? 0 : ($size_x / 5)),
           'stroke','black','stroke-width', 2);    # y axis

##=======   Draw  the SIGNS  =======##
##
my ($h_posx,$h_posy) = $h_pos ? (split/,/,$h_pos) : ($flank_x + $width/2, $flank_y - 1.5 * $size_ht);
$nosign  && (goto END);
my @signs = @symbol;
#$size_sig ||= 0.032 * $width;    ########################################
$column   ||= 2;
my $splitn = int(@signs / $column - 1e-6);
my ($sig_x, $sig_y,$sig_y2);
my @sig_long;
if ($right){
    ($sig_x, $sig_y) =($flank_x + $width + 1.2 * $size_sig, $flank_y + ($height - 1.2 * $size_sig * ($#signs + 1))/2);
    $sig_y2 = $flank_y + 1.2 * $size_sig;
}else{
    ($sig_x, $sig_y) = ($flank_x + $xpolt_unit / 4, $flank_y - 1.2 * $size_sig * ($splitn + 2));
    $sig_y2 = $sig_y;
    foreach (0 .. $column - 1){
        my $s = $_ * ($splitn + 1);
        my $e = $s + $splitn;
        ($e > $#signs) && ($e = $#signs);
        push @sig_long, (longest_str(@signs[$s .. $e]) + 5);
    }
}
if ($sig_pos){
    $sig_pos =~ s/\s+//g;
    ($sig_x, $sig_y) = split /,/, $sig_pos;
}
if (!$right){
    my $size_sig_max = 2 * ($pwidth - $sig_x) / sum(@sig_long);
    ($size_sig_max < $size_sig) && ($size_sig = $size_sig_max);
}
($sig_y2 > $flank_y) && ($h_posy = $sig_y2 - 1.5*$size_ht);
my $y_top = $sig_y;
my $a = 0.7 * $size_sig;    # size length of squear to sign
for (0 .. $#signs){
    my $i = 0;
    if (!$right && $_ && !($_ % ($splitn + 1)))    {
        $sig_x = $sig_x + $size_sig * $sig_long[$i] / 2;
        $sig_y = $y_top;
        $i++;
    }
    $sig_y += 1.2 * $size_sig;
    my $signs_title = ($signs[$_] || 'Null');
    my $stroke_color = ($stroke || $colors[$_]);
    $svg->rect('x',$sig_x,'y',$sig_y - $a,'width', $a,'height', $a,
               'stroke', $stroke_color, 'fill',   $colors[$_]);
    $svg->text('x', $sig_x + 1.5 * $a, 'y', $sig_y,'stroke', 'none','fill','black',
               'font-family','Arial','-cdata', $signs_title,'font-size', $size_sig);
}

END:{
	$h_title && $svg->text('x', $h_posx, 'y', $h_posy,'stroke','none','fill','black',
               '-cdata', $h_title,'font-size', $size_ht,'text-anchor', 'middle','font-family','Arial');
  print $svg->xmlify;
}

#************************************************************#
#
#                         FUNCTION                           #
#
#************************************************************#

#************#
# Function 1

sub sum{
    my $sum_present = 0;
    foreach (@_)    {
        $sum_present += $_;
    }
    $sum_present;
}

#************#
# Function 2
# this function usde to find the max value in an Array

sub max{
    my $max_present = $_[0];
    foreach (@_)    {
        $max_present = $_ if ($_ > $max_present);
    }
    $max_present;
}

#************#
# Function 3
# This function is used to caclutate the min value and the number of value that show in y axis.

sub axis{
    #useage: axis_spli(a[,b,c]),a is the max value in the axis scale polt
    #b is the ratio of the max value to the length of the Y axis.
    #c is for precision, often use 2,4,8,16
    die"the ratio must between 0.5 to 0.98, if not you should revise your figure.\n"  if ($_[1] > 0.98 || $_[1] < 0.5);
    my ($maxv,$rate,$preci) = @_;
    $rate ||= 0.9;
    $preci ||= 2;
    $preci = 2**$preci;
    my ($mbs,$mag) = split/\.?\d?e/,sprintf("%1.1e", $_[0]);# the MSB of the max value in the plot
    $mag =~ s/^\+//;                                        # the order of magnitude of the max value in the plot.
    $mag =~ s/^0*//;
    $mag ||= 0;
    my $k = $rate / (1 - $rate) / $preci;              # the middle value used to caclutate $min_value-
                       # -you can also change preci into 2 or 1, the y-scal will become more precision
    my $min_value;     # the min value show in y axis
    foreach(2,1,0.5,0.25,0.125,0.1,0.05){
    	$min_value = $_;
    	($mbs >= $_ * $k) && last;
    }
    $min_value = $min_value * 10**$mag;
    my $value_number = int($maxv / $min_value - 1e-7) + 1;  # the number of value show in y axis
    ($min_value, $value_number);
}

#************#
# Function 4
# This function is used to caclutate the length of the longtest string in an array

sub longest_str{
    my $sig_long = 0;
    foreach (@_)    {
        my $long = length($_);
        ($long > $sig_long) && ($sig_long = $long);
    }
    $sig_long;
}
