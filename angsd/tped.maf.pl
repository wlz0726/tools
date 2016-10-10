#! /usr/bin/perl
use strict;
use warnings;

my $tped=shift;
die "000.chr.plot.maf.pl tpedFile\n" unless $tped;
my %h;
open(IN, "$tped");
while(<IN>){
    chomp;
    my @a=split (/\t/);
    my @c=split (/\s+/,$a[0]);
    my $id=$c[1];
    
    for(my $i=1;$i< @a;$i++){
        my @b=split(/\s+/,$a[$i]);
        $h{$id}{$b[0]}++;
        $h{$id}{$b[1]}++;
    }
}
close IN;
my $erronum=0;
open(OUT, "> $tped.maf");
foreach my $key (sort keys %h){
    my @a=keys %{$h{$key}};
    if (@a != 2){# || ($h{$key}{$a[0]} + $h{$key}{$a[1]} != 20)){
        print "erro\t$key\t$h{$key}{$a[0]}\n";
        $erronum++;
        next;
    }
    my @b=($h{$key}{$a[0]},$h{$key}{$a[1]});
    my @c=sort {$a<=>$b}@b;
    print OUT "$key\t$c[0]\n";
#    foreach my $key2(sort keys %{$h{$key}}){
#        print OUT "$key\t$key2\t$h{$key}{$key2}\n";
#        print "$key\t$key2\t$h{$key}{$key2}\n";
#    }
}
close OUT;
print "erro num\t$erronum\n";
