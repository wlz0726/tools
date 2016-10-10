#!/usr/bin/perl -w
my $f=shift;

my $num=0;
my $total=0;
open(IN, "samtools view $f|");
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    next if ($num > 1000000);
    $num++;
    $total +=$a[4];
}
close IN;

my $mq=$total/$num;
print "$f\t$num\t$total\t$mq\n";
