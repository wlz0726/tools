#!/usr/bin/env perl
use strict;
use warnings;

my ($inputbed,$poplist,$lenlist,$outprefix,$rawwidth,$rawsplit,$coordinate)=@ARGV;
die "Usage: perl $0 <inputbed.list> <poplist> <chrlengthlist> <outprefix> [width] [one haplotype heigth] [coordinate] 
     
         inputbedlist: file list of bedinput; bedinput format  : Confidence < 0.9 will be colored in grey
                                         Chr     Start(bp)       End(bp) Vit     Start(cM)       End(cM) Fbk     Confidence      Posterior(indicus,taurus)
              poplist: PopA    AGS10A
        chrlengthlist: 1       158334843
            outprefix: outprefix [out]

                width: svg width, this value should > 200. default: [600]
 one haplotype heigth: this value can be set to 10 15 20 ... default: [5]
           coordinate: coordinate bar [50000000]


\n" if (! $lenlist);

# default set
$outprefix ||='out';
$coordinate ||= '50000000';
print $coordinate;
my $coordinate_Mb=$coordinate/1000000;

my %bedfile=&getinputinfo($inputbed,$poplist);
my %col=('indicus'=>'#E31A1C','taurus'=>'#1F78B4','unknown'=>'#c8c8c8');
my %len=&getchrlength($lenlist);

for my $chr (sort keys %bedfile){
    my $len=$len{$chr};
    my @pop=sort keys %{$bedfile{$chr}};
    my %pop;
    my $indnum=0;
    for my $pop (@pop){
        $indnum++;
        for my $ind (sort keys %{$bedfile{$chr}{$pop}}){
            $indnum += 2;
            $pop{$pop} +=2;
        }
    }
    $indnum=$indnum-1;
    my $popnum=@pop;
    my $width="600";  ### default figure width
    $width=$rawwidth if ($rawwidth);
    my $split=10;
    $split=$rawsplit if ($rawsplit);
    my $height=40+60+($split*$indnum);
    open (O,"> $outprefix.Chr$chr-Ancestry.svg")||die"$!";
    print O "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!-- Generator: Customed by yumtaoist)  -->
<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\"><svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" width=\"",$width,"px\" height=\"",$height,"px\" viewBox=\"0 0 ",$width," ",$height,"\" enable-background=\"new 0 0 ",$width," ",$height,"\" xml:space=\"preserve\">\n";
    ## top
    my $toppx=24;
    my $wordtop="Chromosome $chr";
    my $topx=($width/2)-(length($wordtop)*0.5*$toppx/1.8);
    my $topy=30;
    print O "\t<text x=\"$topx\" y=\"$topy\" style=\"font-size:$toppx","px;font-weight:bold;\" >Chromosome $chr</text>\n\n";
    ## bottom
    my $bottomy1=$height-60;
    my $bottomy2=$height-45;
    my $bottomy3=$height-24;
    my $bottompx=20;
    for (my $i=0;$i<$len;$i=$i+$coordinate){ # coordinate window
        my $bottomx=100+(($i/$len)*($width-200));
        print O "\t<line fill=\"#000000\" stroke=\"#000000\" stroke-width=\"1\" stroke-miterlimit=\"10\" x1=\"$bottomx\" y1=\"$bottomy1\" x2=\"$bottomx\" y2=\"$bottomy2\" />\n";
        my $j=int($i/$coordinate)*$coordinate_Mb;
        my $bottomx2=$bottomx-(length($j)*0.5*$bottompx/2);
        print O "\t<text x=\"$bottomx2\" y=\"$bottomy3\" style=\"font-size:$bottompx","px;\">$j</text>\n";
    }
    print O "\t<text x=\"",(($width/2)-(length('position (Mb)')*0.5*22/2)),"\" y=\"",$height-5,"\" style=\"font-size:22","px;\">position (Mb)</text>\n\n";
    ## left
    my $splitnum=$indnum;
    my $leftpx=12;
    #for (my $i=0;$i<$splitnum;$i++){
    my $leftnum=0;
    for (my $i=0;$i<@pop;$i++){
        my @ind=sort keys %{$bedfile{$chr}{$pop[$i]}};
        for (my $j=0;$j<@ind;$j++){
            $leftnum += 2;
            my $leftx1=90;
            my $leftx2=100;
            my $lefty1=((40+($i*$split)+($leftnum*$split)) + (40+($i*$split)+(($leftnum-2)*$split)))/2;
            my $lefty2=$lefty1+($split*0.25);
            print O "\t<line fill=\"#000000\" stroke=\"#000000\" stroke-width=\"1\" stroke-miterlimit=\"10\" x1=\"$leftx1\" y1=\"$lefty1\" x2=\"$leftx2\" y2=\"$lefty1\" />\n";
            print O "\t<text x=\"10\" y=\"$lefty2\" style=\"font-size:$leftpx","px;\">$ind[$j]</text>\n";
        }
    }
    print O "\n";
    ## right
    my $righty=40-$split;
    for (my $i=0;$i<@pop;$i++){
        my $popinds=$pop{$pop[$i]};
        my $righty1=$righty+$split;
        my $righty2=$righty1+($popinds*$split);
        my $rightymid=$righty1+($popinds*$split/2);
        $righty=$righty2;
        my $rightx0=$width-100;
        my $rightx1=$width-95;
        my $rightx2=$width-85;
        my $rightx3=$width-80;
        print O "\t<rect x=\"$rightx0\" y=\"$righty1\" width=\"5px\" height=\"",$popinds*$split,"\" fill=\"#000000\" />\n";
        print O "\t<line fill=\"#000000\" stroke=\"#000000\" stroke-width=\"1\" stroke-miterlimit=\"10\" x1=\"$rightx1\"  y1=\"$rightymid\" x2=\"$rightx2\"  y2=\"$rightymid\" />\n";
        print O "\t<text x=\"$rightx3\" y=\"",$rightymid+($split*0.5),"\" style=\"font-size:24px;font-weight:bold;\" >$pop[$i]</text>\n";
    }
    print O "\n";
    ## file plot

    my $filenum=0;
    for (my $i=0;$i<@pop;$i++){
        my $popid=$pop[$i];
        my @indid=sort keys %{$bedfile{$chr}{$popid}};
        for (my $j=0;$j<@indid;$j++){
            my $indid=$indid[$j];
            for my $haplotype (sort keys %{$bedfile{$chr}{$popid}{$indid}}){
	$filenum++;
	my $readfile=$bedfile{$chr}{$popid}{$indid}{$haplotype};
	my $filex=100;
	my $filey=40-$split+($i*$split)+($filenum*$split);
	print O "\t<rect x=\"$filex\" y=\"$filey\" width=\"",$width-200,"\" height=\"$split\" fill=\"$col{unknown}\" />\n";
	open (F,"$readfile")||die"$readfile\n";
	while (<F>) {
	    chomp;
	    my @a=split(/\s+/,$_);
	    next if /^Chr\s+/;
	    next if $a[7]<0.9; # confident value 0.9
	    my $startx=$filex+(($a[1]/$len)*($width-200));
	    my $extand=(($a[2]-$a[1]+1)/$len)*($width-200);
	    print O "\t<rect x=\"$startx\" y=\"$filey\"  width=\"$extand\" height=\"$split\" fill=\"$col{$a[3]}\" />\n";
	}
	close F;
	print O "\n";
            }
        }
    }

    print O "</svg>\n";
    close O;
}

sub getinputinfo{
    my ($in1,$in2)=@_;
    my %r1;
    my %r2;
    open (F,"$in2")||die"$!";
    while (<F>) {
        chomp;
        my @a=split(/\s+/,$_);
        $r1{$a[1]}=$a[0];
    }
    close F;
    open (F,"$in1")||die"$!";
    while (<F>) {
        chomp;
        /chr(\d+)_(\S+)_(A|B).bed.txt/ or die "wrong type $_\n"; ## bed name format
        my $pop=$r1{$2};
        #my $ind="$2-$3";
        $r2{$1}{$pop}{$2}{$3}=$_;
    }
    close F;
    return %r2;
}
sub getchrlength{
    my ($in)=@_;
    my %r1;
    open (F,"$in")||die"$!";
    while (<F>) {
        chomp;
        my @a=split(/\s+/,$_);
        $r1{$a[0]}=$a[1];
    }
    close F;
    return %r1;
}
