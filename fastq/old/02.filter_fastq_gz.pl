#! /usr/bin/perl
use strict;
use warnings;


my $file1=shift;
my $file2=shift;
my $out_prefix=shift;
my $Qstart=shift;
if(!$file1 || !$file2 || !$out_prefix){
    die "Usage:\n$0 \$fq1.gz \$fq2.gz \$out_prefix \$Qstart(33_or_64)\n";
}
my $out1="$out_prefix.1.filter.fq.gz";
my $out2="$out_prefix.2.filter.fq.gz";
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

    my $test2=filter($l2,$l4);
    #print "$test2\n";
    next if($test2==0);
    my $test6=filter($l6,$l8);
    #print "$test6\n";
    next if($test6==0);

    #$l1=~/^(\S+)/;
    #$l1=$1."/1\n";
    #$l5=~/^(\S+)/;
    #$l5=$1."/2\n";
    print O1 "$l1","$l2","+\n","$l4";
    print O2 "$l5","$l6","+\n","$l8";
    #last;
}
close I1;
close I2;
close O1;
close O2;

sub filter{
    my ($seq,$qual)=@_;
    chomp $seq;
    chomp $qual;
    #print "SEQO $seq\n";
    my $len=length($seq);
    #print "LEN $len\n";
    return(0) if($len==0);
    my $n=$seq;
    $n=~s/N//g;
    #print "SEQ $n\n";
    my $lenN=length($n);
    #print "LENN $lenN\n";
    ########################################### N percentage < 10%
    return(0) if($lenN/$len<0.90);
    my @quality=split(//,$qual);
    my $invalid=0;
    #print "\n";
    foreach my $a(@quality){
        my $b=ord($a)-$Qstart;
        ########################################### Qual < 7  bigger than 65%
        $invalid++ if($b<=7);
        #print "$b ";
    }
    #print "\n";
    #print "INVA $invalid\n";
    return(0) if($invalid/$len>=0.65);
    return(1);
}
