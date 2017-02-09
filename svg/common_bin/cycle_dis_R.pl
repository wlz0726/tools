#!/usr/bin/perl -w 
use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
my ($title,$width,$heigh,$legend,$rank,$others,$nohead);
GetOptions("title:s"=>\$title,"width:i"=>\$width,"heigh:i"=>\$heigh,"legend"=>\$legend,
    "rank:s"=>\$rank,"others:s"=>\$others,"nohead"=>\$nohead);
@ARGV || die "Usage perl $0  <infile> [out.png]
    infile <file>   input file: sign\tstat_num
    out.png <file>  putfile name, default=<infile>.png
    -nohead         not use the head line of infile
    -rank <str>     the rank of data sign,num at infile, default=0,1
    -others <str>   add other sign,tolnum, default not set
    -title <str>    figure title, derault=' '
    -legend         show legend, default not show
    -width <num>    figure width, defualt=1000
    -heigh <num>    figure heigh, defualt=800\n";
my ($inf,$outfile) = @ARGV;
(-s $inf) || die"error: infile $inf is empty\n";
$outfile ||= (split/\//,$inf)[-1] . ".png";
($outfile=~/\.png$/) || ($outfile .= '.png');
$title ||= ' ';
$width ||= 1000;
$heigh ||= 800;
my $leg = $legend ? " " : "#";
my %statistics;# = split/\s+/,`awk '(!/^#/ && \$2~/[0-9]/){print \$1,\$2}' $inf`;
my @sel = $rank ? split/,/,$rank : ();
my $tol;
open IN,$inf || die$!;
$nohead && <IN>;
foreach(<IN>){
    m/\S\s+\S/ || next;
    my @l = /\t/ ? (split/\t/) : split;
    @sel && (@l = @l[@sel]);
    (!$l[1] || m/^#/ || m/chr_?id/i || m/total/i) && next;
    $statistics{$l[0]} = $l[1];
    $tol += $l[1];
}
close IN;
if($others && $others=~/(\S+),(\S+)/){
    $statistics{$1} = $2 - $tol;
}
my $num = scalar keys %statistics;
my @key = $legend ? map{"'$_'"} sort keys %statistics : map{"'$_($statistics{$_})'"} sort keys %statistics;
my $name = join ',',@key;
my $scale = join ',', map{$statistics{$_}} sort keys %statistics;
my ($w,$h) = (0.8*$width,0.15*$heigh);
my $pie=qq~
png("$outfile",width=$width,height=$heigh);
par(cex=1.5,cex.lab=2,mar=c(1.5,1.5,1,3));
pie.sales=c($scale);
names(pie.sales)=c($name);
#pie.col=c(1:$num)+1;
pie.col=rainbow($num);
pie(pie.sales,col=pie.col);
#title(xlab = \"$title\",line=-2);
$leg legend(1.1,-0.4,c($scale),col=pie.col,pch=15,cex=0.8,bty="y")
#legend($w,$h,c($scale),col=pie.col,lty = 2:1,cex = 0.8, bty = "n");
title(main="$title",font=1,line=-2);
~;
my $rsh = "xx.$$.R";
open OUT,">$rsh";
print OUT $pie;
system "/opt/blc/genome/biosoft/R/bin/R  CMD  BATCH";
system  "/opt/blc/genome/biosoft/R/bin/Rscript $rsh;rm $rsh";
(-s ".R.Rout") && `rm .R.Rout`;
