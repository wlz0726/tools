#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=2 ) {
	print "perl $0 <vcf><snp>\n";
	exit 0;
}
my ($in,$out)=@ARGV;
  if ($in=~/\.gz$/){
    open IN,"zcat $in|" or die $!;
       }
    else{
   open IN,$in or die $!;
         }
open OUT,'>',$out or die $!;
while(<IN>){
next if(/^#/);
chomp;
my @s=split(/\s+/,$_);
my ($chr,$pos,$ref,$alt,$geno)=(split(/\s+/,$_))[0,1,3,4,-1];
my $tem=(split(/\:/,$geno))[0];
next if($tem eq "./.");
next if($tem eq "0/0");
next if($alt eq ".");
next if(/INDEL/);
next if($chr=~/_/);
my ($GT,$AD,$dp,$GQ,$PL)=(split(/\:/,$geno))[0,1,2,3,4];
next if($GQ<=10);
#chr14   3117    .       G       A       104.68  PASS    .       GT:AD:DP:GQ:PL  1/1:0,2:2:6:73,6,0
#=======================================
my @alt=split(/,/,$alt);
my %hash=();$hash{0}=$ref;
my $number=scalar @alt; my $genotype="";my $geno_2="";my $tem_geno="";my $type="";
my $i=1;
while($i<=$number){
    $hash{$i}=$alt[$i-1];
    $i++;
}
if($geno=~/(\d+)\/(\d+)/){
    $geno_2="$hash{$1}\/$hash{$2}";
    $tem_geno="$hash{$1}$hash{$2}"; 
    if($1==$2) {$type="hom";}else {$type="het";}
}
elsif($geno=~/(\d+)\|(\d+)/) {
    $geno_2="$hash{$1}\|$hash{$2}";
    $tem_geno="$hash{$1}$hash{$2}";
    if($1==$2) {$type="hom";}else {$type="het";}
}
else {die "$geno :wrong genotype";}
if($type eq "hom"){
    $genotype=substr($tem_geno,0,1);
}
else{
if($tem_geno=~/AC/ || $tem_geno=~/CA/) {$genotype="M";}
elsif($tem_geno=~/AG/ || $tem_geno=~/GA/){$genotype="R";}
elsif($tem_geno=~/AT/ || $tem_geno=~/TA/){$genotype="W";}
elsif($tem_geno=~/GC/ || $tem_geno=~/CG/){$genotype="S";}
elsif($tem_geno=~/TC/ || $tem_geno=~/CT/){$genotype="Y";}
elsif($tem_geno=~/TG/ || $tem_geno=~/GT/) {$genotype="K";}
else{die "wrong:$_\n";}
}
print OUT "$chr\t$pos\t$ref\t$genotype\n";
}

close OUT;
close IN;
