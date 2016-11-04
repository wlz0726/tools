#! /usr/bin/perl
use strict;
use warnings;

my $samtools_vcf=shift;
my $angsd_tped=shift;
die "perl compare.angsd.samtools.pl samtools_vcf angsd_tped\n" unless $angsd_tped;

my %h;
open(IN, "$samtools_vcf");
while(<IN>){
    chomp;
    next if (/^#/);
    my @a=split (/\s+/);
    $h{$a[1]}++;
}
close IN;
my $num1=keys %h;
my $num2=0;
my $overlap=0;
open(IN, "$angsd_tped");
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    if(exists $h{$a[3]}){
        $overlap++;
    }
    $num2++;
}
close IN;
my $per1=$overlap/$num1;
my $per2=$overlap/$num2;
open(OUT,"> $samtools_vcf.$angsd_tped.compare.log");
print OUT "$samtools_vcf\t$num1\t$per1\n$angsd_tped\t$num2\t$per2\noverlap SNPs\t$overlap\n";
print "$samtools_vcf\t$num1\t$per1\n$angsd_tped\t$num2\t$per2\noverlap SNPs\t$overlap\n";
close OUT;
