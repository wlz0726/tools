#! /usr/bin/perl
use strict;
use warnings;

my $f=shift; # keepv2.covarites
my $pc_num=shift;
die "$0 <keep.covarites> [4]
keep.covarites:
FID IID AGE GENDER C1 C2 C3 C4
002442984c37af4ebefaf77118e41af6 002442984c37af4ebefaf77118e41af6 35 1 0.0151354 -0.00495096 0.0130832 -0.0177045
0024cf3d2cefebfd573438cb2dff0f66 0024cf3d2cefebfd573438cb2dff0f66 22 1 0.00015067 -0.00342325 -0.00462128 -0.0153405
00342aea6250d2ad6f173cec55a4b71d 00342aea6250d2ad6f173cec55a4b71d 20 1 -0.00320493 -0.0175754 -0.00376158 0.0125457
\n"unless $f;

$pc_num||=4;

my $out="$f.ggplot2";
open(I,"< $f");
<I>;
my @head=("FID\tIID\tAGE\tGENDER");

my $outdir="$f.pcaplot";
`mkdir $outdir`unless -e $outdir;

for(my $i=1;$i<=$pc_num;$i++){
    my $h="PC$i";
    push @head,$h;
}
push @head,"Populations";
push @head,"Regions";
my $head=join "\t",@head;
open(O,"> $out");
print O "$head\n";
<I>;
while(<I>){
    chomp;
    s/^\s+//;
    my @a=split(/\s+/);
        
    print O "$_\t$a[3]\t$a[3]\n";
}
close I;
close O;

$f=~/\/([^\/]*)$/;
my $id=$1;

open(R,"> $f.R");
print R "
library(\"ggplot2\");
library(RColorBrewer)
mycolor =brewer.pal(n=8, 'Set1')
mycolor2=c(mycolor[1:5],mycolor[7:8])

a=read.table(\"$f.ggplot2\",header=T)
pdf(file=\"$outdir/$id.PC1_PC2.pdf\")
ggplot(a,aes(PC1,PC2,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()

pdf(file=\"$outdir/$id.PC1_PC3.pdf\");
ggplot(a,aes(PC1,PC3,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()

pdf(file=\"$outdir/$id.PC1_PC4.pdf\");
ggplot(a,aes(PC1,PC4,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()

pdf(file=\"$outdir/$id.PC2_PC3.pdf\");
ggplot(a,aes(PC2,PC3,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()

pdf(file=\"$outdir/$id.PC2_PC4.pdf\");
ggplot(a,aes(PC2,PC4,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()

pdf(file=\"$outdir/$id.PC3_PC4.pdf\");
ggplot(a,aes(PC3,PC4,color=factor(Populations)))+geom_point(shape=1,size=3)+theme_bw()+scale_color_manual(values=c(seq(0:18),seq(0,18),seq(0,18)))
dev.off()
";
close R;
`Rscript $f.R`;
