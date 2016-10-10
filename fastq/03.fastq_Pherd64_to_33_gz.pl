#! /usr/bin/perl
use strict;
use warnings;

my $file1=shift;
my $file2=shift;
my $out_prefix=shift;
#my $Qstart="64";
if(!$file1 || !$file2 || !$out_prefix){
    die "Usage:\n$0 \$fq1.gz \$fq2.gz \$out_prefix\n";
}
my $out1="$out_prefix.1.recode.fq.gz";
my $out2="$out_prefix.2.recode.fq.gz";
open(I1,"zcat $file1 |")||die("$!\n");
open(I2,"zcat $file2 |")||die("$!\n");
open(O1,"| gzip -c > $out1")||die("$!\n");
open(O2,"| gzip -c > $out2")||die("$!\n");
while(<I1>){
    my $l1=$_;
    my $l2=<I1>;
    my $l3=<I1>;
    my $l4=<I1>;
    my $l5=<I2>;
    my $l6=<I2>;
    my $l7=<I2>;
    my $l8=<I2>;
    
    my $qual1=RecodeQual($l4);
    my $qual2=RecodeQual($l8);
    
    print O1 "$l1","$l2","+\n","$qual1\n";
    print O2 "$l5","$l6","+\n","$qual2\n";
}
close I1;
close I2;
close O1;
close O2;

sub RecodeQual{
    my ($qual)=@_;
    chomp $qual;
    my @a=split("",$qual);
    my @b;
    foreach my $q(@a){
        my $Q=ord($q) - 64;
        my $rq=chr(($Q<=93 ? $Q : 93) + 33);
        push (@b,$rq);
    }
    my $recodeq=join("",@b);
    return $recodeq;
}
