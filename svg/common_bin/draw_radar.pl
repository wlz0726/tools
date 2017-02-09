#!/usr/bin/perl -w 
use strict;
use Getopt::Long;
my ($width,$height,$edge,$wl,$fsize,$un,$color,$title) = (500,400,0,0,20);
GetOptions("width:i"=>\$width,"height:i"=>\$height,"edge:i"=>\$edge,
    "color:s"=>\$color,"wl:f"=>\$wl,"un:s"=>\$un,"title:s"=>\$title);
$edge ||= $height/3;
$wl ||= $edge/100;
@ARGV || die"usage: perl $0 <in.table> > out.svg
    -width <num>        figure width, defualt=500
    -height <num>       figure height, defualt=400
    -edge <num>         figure edge, default=height/3
    -wl <flo>           line width, default=edge/100
    -un <str>           unit,number, default auto caculate
    -title <str>        set title, default not set
    -fsize <flo>        font size, defualt=20
    -color <str>        set line color, default auto

<in.table> form:
\t\@sign
group1  \@data1
group2  \@data2
....\n";
#connect: wenbin Liu
my $inf = shift;
(-s $inf) || die"error: can't find file $inf, $!";
open IN,$inf || die$!;
my $head_line = <IN>;
my @plots = ($head_line =~ /\t/) ? (split /\t/,$head_line) :
    (split/\s+/,$head_line);
shift @plots;
my (@group,@data);
my $max = 0;
while(<IN>){
    my @l = split/\s+/;
    push @group,(shift @l);
    push @data,[@l];
    foreach(@l){
        ($_ > $max) && ($max = $_);
    }
}

my ($unit,$num) = $un ? split/,/,$un : axis_split($max);

#===============================================
#for draw
my $edgex = $edge/2;
my $rankn = (@group > 20) ? 8 : (@group >=9) ? 5 : (@group >=7) ? 4 : 3;
my $lown = int(@group/$rankn);
(@group > $lown * $rankn) && ($lown++);
my $edgey = 1.2*0.8*$fsize*$lown + 0.1*$edge;
my ($pwidth,$pheight) = ($width+2*$edgex,$height+$edge+$edgey);
use SVG;
my $svg = SVG->new(width => $pwidth,height => $pheight);
my ($rx,$ry) = ($edgex + $width/2, $edge/2+$height/2);
my $r = 0.45*($width>$height ? $height : $width);
my $pi ||= atan2(1,1)*4;
my $r_rate = $r/$unit/$num;
my $a_rate = 2*$pi/@plots;
my @colors = $color ? split/,/,$color : qw(crimson blue orange lightseagreen mediumpurple
    palegreen lightcoral dodgerblue lawngreen red olive indigogreen yellow fuchsia salmon
    mediumslateblue darkviolet purple sienna  black skyblue);#20 colors
#cycle
my $s_size = 0.6*$fsize;
($s_size > 2*$r/$num) && ($s_size = 2*$r/$num);
foreach(1..$num){
    my $cr = $r * $_ / $num;
    draw_sycle($r_rate,$a_rate,$cr,$#plots+1,$wl/2,$_*$unit,$s_size);
}
foreach(0..$#data){
    my $i = $#data - $_;
    draw_sycle($r_rate,$a_rate,0,$#plots+1,2*$wl,0,0,$data[$i],$colors[$i]);
}
foreach(0..$#plots){
    my $ftype = ($_==0 || $_ == $#plots/2+0.5) ? 'middle' : ($_ < $#plots/2+0.5) ? 'start' : 'end';
    my ($sx,$sy) = XY_change($_,$r,1,$a_rate);
    $svg->line('x1',$rx,'y1',$ry,'x2',$sx,'y2',$sy,'stroke', 'black', 'stroke-width',$wl/2);
    ($sx,$sy) = XY_change($_,$r+$fsize*(0.1+abs(sin($pi*$_/@plots))),1,$a_rate);
    $svg->text('x',$sx,'y',$sy,'stroke','none','fill','black','-cdata',$plots[$_],
        'font-size', $fsize,'text-anchor',$ftype,'font-family','Arial');
}
#title
if($title){
    my $t_size = 1.2*$fsize;
    $svg->text('x',$edgex+$width/2,'y',0.5*$edge-1.2*$fsize,'stroke','none','fill','black',
        '-cdata',$title,'font-size',$t_size,'text-anchor','middle','font-family','Arial');
}
#symbol
my $len = 30;
$fsize *= 0.8;
my $maxlen = 0;
foreach(@group){
    my $slen = length($_)/2;
    ($slen > $maxlen) && ($maxlen = $slen);
}
my $may_size1 = (($edgex+$width)/$rankn - $len)/($maxlen+2.5);
my $may_size2 = ($edgey-$fsize)/1.2/$lown;
($fsize > $may_size1) && ($fsize = $may_size1);
($fsize > $may_size2) && ($fsize = $may_size2);
my $symb_len = $len + ($maxlen+2.5)*$fsize;
my $temp_rankn = (@group > $rankn) ? $rankn : @group;
my ($symb_x,$symb_y) = ($edgex+($width-$symb_len*$temp_rankn)/2, 0.55*$edge+$height+$fsize);
my $symb_x0 = $symb_x;
foreach(0..$#group){
    if($_ && $_ % $rankn == 0){
        $symb_x = $symb_x0;
        $symb_y += 1.2*$fsize;
    }
    draw_symbol($symb_x,$symb_y,$len,2*$wl,$fsize,$group[$_],$colors[$_]);
    $symb_x += $symb_len;
}

print $svg->xmlify;

#============================================================================================
#sub0
#=============
sub XY_change{
    my ($x,$y,$r_rate,$a_rate) = @_;
    my $cr = $y * $r_rate;
    my $ca = $x * $a_rate;
    ($rx + $cr * sin($ca), $ry - $cr*cos($ca));
}
sub draw_sycle{
    my ($r_rate,$a_rate,$cr,$plot_num,$wl,$text,$fsize,$data,$color) = @_;
    my @xy;
    $color ||= 'black';
    my ($x,$y) = $data ? XY_change(0,$data->[0],$r_rate,$a_rate) : XY_change(0,$cr,1,$a_rate);
    my ($x1,$y1,$x2,$y2) = ($x,$y);
    foreach(1..$plot_num-1){
        ($x2,$y2) = $data ? XY_change($_,$data->[$_],$r_rate,$a_rate) : XY_change($_,$cr,1,$a_rate);
        $svg->line('x1',$x1,'y1',$y1,'x2',$x2,'y2',$y2,'stroke', $color, 'stroke-width',$wl);
        ($x1,$y1) = ($x2,$y2);
    }
    $svg->line('x1',$x1,'y1',$y1,'x2',$x,'y2',$y,'stroke', $color, 'stroke-width',$wl);
    if($text){
        my ($tx,$ty) = XY_change(-0.5,($cr+0.14*$fsize)*cos($pi/$plot_num),1,$a_rate);
        my $angle = 180/$plot_num;
        my $g = $svg->group("transform"=>"rotate(-$angle,$tx,$ty)");
        $g->text('x',$tx,'y',$ty,'stroke','none','fill','black','-cdata',$text,
                'font-size', $fsize,'text-anchor','middle','font-family','Arial');
    }
}
sub draw_symbol{
    my ($sx,$sy,$len,$wl,$fsize,$text,$color) = @_;
    $svg->line('x1',$sx,'y1',$sy-0.36*$fsize,'x2',$sx+$len,'y2',$sy-0.36*$fsize,
            'stroke', $color, 'stroke-width',$wl);
    $svg->text('x',$sx+$len + $fsize/2,'y',$sy,'stroke','none','fill','black','-cdata',$text,
            'font-size', $fsize,'text-anchor','start','font-family','Arial');
}

#sub1
#=============#
sub axis_split
#=============#
{
    #useage: axis_spli(a[,b,c]),a is the max value in the axis scale polt
    #b is the ratio of the max value to the length of the Y axis.
    #c is for precision, often use 2,4,8,16
    my ($maxv,$rate,$preci) = @_;
    $rate ||= 0.9;
    die"the ratio must between 0.5 to 0.98, if not you should revise your figure.\n"  if ($rate > 0.98 || $rate < 0.5);
    $preci ||= 1;
    $preci = 2**$preci;
    sprintf("%1.1e", $maxv) =~ /^(.)(.*)e(.*)/;
    my $mbs = $1;    # the MSB of the max value in the plot
    my $mag = $3;    # the order of magnitude of the max value in the plot.
    $mag =~ s/^\+//;
    $mag =~ s/^0*//;
    $mag  ||= 0;
    my $k = $rate / (1 - $rate) / $preci;              # the middle value used to caclutate $min_value-
                       # -you can also change preci into 2 or 1, the y-scal will become more precision
    my $min_value;     # the min value show in y axis
    foreach(2,1,0.5,0.25,0.125,0.1,0.05){
        $min_value = $_;
        ($mbs >= $_ * $k) && last;
    }
    $min_value = 2*$min_value * 10**$mag;
    my $value_number = int($maxv / $min_value);  # the number of value show in y axis
    ($value_number * $min_value == $maxv) || ($value_number++);
    ($min_value, $value_number);
}
