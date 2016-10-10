#!/usr/bin/perl -w
my $f=shift;
open(IN,"$f");
open(OUT,"> $f.DOM.geno");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $a[2] =~ /(.*):(.*)/;
    my $chr=$1;
    my $pos=$2;
    my @b6=split(/\//,$a[6]);
    my @b7=split(/\//,$a[7]);
    next if ($b6[0] < $b6[1]);
    next if ($b7[0] > $b7[1]);
    
    next if ($b7[0] > 0);
    print OUT "$chr\t$pos\t$a[6]\t$a[7]\n";
}
close IN;
close OUT;
