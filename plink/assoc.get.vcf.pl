#!/usr/bin/perl
#my $vcf=shift;
my $pos=shift;
die "$0 posfile\n" unless $pos;
my %h;
open(IN,"$pos");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $h{$a[0]}{$a[1]}++;
}
close IN;

#my $vcf="/home/share/user/user104/projects/yak/association/02.vcf.phased/01.plink/b4.vcf.fAR0.5.vcf";
my $vcf="/home/share/user/user104/projects/yak/yakres.bgi.201403/BWA.Rehead.Realign.FirstCall.samtools.3.filter/00.beagle.phase/b4.vcf.fAR0.5.vcf";
open(IN,"$vcf");
open(OUT,"> $pos.vcf");
while(<IN>){
    chomp;
    if(/#/){
        print OUT "$_\n";
        next;
    }
    my @a=split(/\s+/);
    if(exists $h{$a[0]}{$a[1]}){
        print OUT "$_\n";
    }
}
close IN;
close OUT;
