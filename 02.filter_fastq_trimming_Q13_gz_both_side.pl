#! /usr/bin/perl
use strict;
use warnings;

my $file1=shift;
my $file2=shift;
my $out_prefix=shift;
my $Qstart=shift;
my $readsLenth=shift;
if(!$file1 || !$file2 || !$out_prefix || !$Qstart || !$readsLenth){
    die "Usage:\n$0 \$fq1.gz \$fq2.gz \$out_prefix \$Qstart(33_or_64) \$readsLenth\n";
}
my $out1="$out_prefix.1.TrimTwoSide.fq.gz";
my $out2="$out_prefix.2.TrimTwoSide.fq.gz";
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
    
    my @reads1=trimming($l2,$l4);
    next if($reads1[0] eq "nan");
    my @reads2=trimming($l6,$l8);
    next if($reads2[0] eq "nan");
    
    my $test2=filter($reads1[0],$reads1[1]);
    next if($test2==0);
    my $test6=filter($reads2[0],$reads2[1]);
    next if($test6==0);
    
    print O1 "$l1","$reads1[0]\n","+\n","$reads1[1]\n";
    print O2 "$l5","$reads2[0]\n","+\n","$reads2[1]\n";
}
close I1;
close I2;
close O1;
close O2;

sub filter{
    my ($seq,$qual)=@_;
    chomp $seq;
    chomp $qual;
    my $len=length($seq);
    return(0) if($len==0);
    my $n=$seq;
    $n=~s/N//g;
    my $lenN=length($n);
    ########################################### N percentage < 10%
    return(0) if($lenN/$len<0.90);
    my @quality=split(//,$qual);
    my $invalid=0;
    foreach my $a(@quality){
        my $b=ord($a)-$Qstart;
        $invalid++ if($b<=7);
    }
    ########################################### Qual < 7  bigger than 65%
    return(0) if($invalid/$len>=0.65);
    return(1);
}
########################################### 3bp sliding window; trim mean qual < 13; trimmed reads longer than 45 bp
sub trimming{
    my ($seq,$qual)=@_;
    chomp $seq;
    chomp $qual;
    my @a=split("",$qual);
    my @b=split("",$seq);
    my ($trimedqual,$trimedseq)=("nan","nan");
    while(@a > 3){
        my @origina=@a;
        my @originb=@b;
        my $b1=shift @a;shift @b;
        my $qb1=ord($b1);
        my $b2=shift @a;shift @b;
        my $qb2=ord($b2);
        my $b3=shift @a;shift @b;
        my $qb3=ord($b3);
        ########################################### set qual 13
        if(((($qb1+$qb2+$qb3)/3)-$Qstart) < 13){
            next;
        }else{
            $trimedqual=join("",@origina);
            $trimedseq=join("",@originb);
            last;
        }
    }
    my @a2=split("",$trimedqual);
    my @b2=split("",$trimedseq);
    ($trimedqual,$trimedseq)=("nan","nan");
    while(@a2 > 3){
        my @origina=@a2;
        my @originb=@b2;
        my $b1=pop @a2;pop @b2;
        my $qb1=ord($b1);
        my $b2=pop @a2;pop @b2;
        my $qb2=ord($b2);
        my $b3=pop @a2;pop @b2;
        my $qb3=ord($b3);
        ########################################### set qual 13
        if(((($qb1+$qb2+$qb3)/3)-$Qstart) < 13){
            next;
        }else{
            $trimedqual=join("",@origina);
            $trimedseq=join("",@originb);
            last;
        }
    }
    my @c;
    if(length($trimedseq)>(int($readsLenth/2)-5)){
        @c=($trimedseq,$trimedqual);
    }else{
        @c=("nan","nan");
    }
    return @c;
}

