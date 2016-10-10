#!/usr/bin/perl

my $f=shift;
my $out="$f.infoall";
my $gff="/home/share/data/genome/Bos_grunniens/00.Genome/YakGenome1.1/02.Annotation/01.gene/yak.gene/yak.gene.20110308.fixed.gff";
my $utr_region="2000";

my %h;
my $num;
my $cdsnum;
open(IN,"$gff");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    my $chr=$a[0];
    $a[8] =~ /ID=([^;]+);/;
    my $name=$1;
    if($a[2] =~ /mRNA/){
        $num++;
        $h{$chr}{$num}{start_long}=$a[3]-$utr_region;
        $h{$chr}{$num}{end_long}=$a[4]+$utr_region;
        $h{$chr}{$num}{start}=$a[3];
        $h{$chr}{$num}{end}=$a[4];
        $h{$chr}{$num}{name}=$name;
        $h{$chr}{$num}{stand}=$a[6];
    }elsif($a[2] =~ /CDS/){
        $cdsnum++;
        $h{$chr}{$num}{$cdsnum}{start}=$a[3];
        $h{$chr}{$num}{$cdsnum}{end}=$a[4];
    }
}
close IN;

open(IN,"$f");
open(OUT,"> $out");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    my $chr=$a[0];
    my $i=$a[1];
    #next if(!$i =~ /\d+/);
    #print "$a[1]\n";die;
    my $gene=0;
    my $mrna=0;
    my $cds=0;
    my $name;
    my $stand;
    if(exists $h{$chr}){
        foreach my $num(keys %{$h{$chr}}){
            if($i >= $h{$chr}{$num}{start_long} && $i <= $h{$chr}{$num}{end_long}){
	$gene=1;
	
	$name=$h{$chr}{$num}{name};
	$stand=$h{$chr}{$num}{stand};
	if($i >= $h{$chr}{$num}{start} && $i <= $h{$chr}{$num}{end}){
	    $mrna=1;
	    foreach my $cdsnum(keys %{$h{$chr}{$num}}){
	        if($i >= $h{$chr}{$num}{$cdsnum}{start} && $i <= $h{$chr}{$num}{$cdsnum}{end}){
	            $cds=1;
	        }
	    }
	}
            }
        }
        if($gene==1 && $mrna==1 && $cds==1){
            print OUT "$_\texon\t$name\t$stand\n";
        }elsif($gene==1 && $mrna==1 && $cds==0){
            print OUT "$chr\t$i\tintron\t$name\t$stand\n";
        }elsif($gene==1 && $mrna==0 && $cds==0){
            print OUT "$chr\t$i\tutr\t$name\t$stand\n";
        }elsif($gene==0 && $mrna==0 && $cds==0){
            print OUT "$chr\t$i\tintergenic\n";
        }
    }
}
close IN;
close OUT;
