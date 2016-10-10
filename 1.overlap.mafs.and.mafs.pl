#! /usr/bin/perl
use strict;
use warnings;
my $mafs1=shift;
my $mafs2=shift;
die "1.overlap.of.snp.pl pop1.mafs pop2.mafs\n"unless $mafs2;
my ($num1,%h1)=&readmafs($mafs1);
my ($num2,%h2)=&readmafs($mafs2);

my $overlap=0;
foreach my $key1(keys %h1){
    foreach my $key2(keys %{$h1{$key1}}){
        if(exists $h2{$key1}{$key2}){
            $overlap++;
        }
    }
}
open (OUT,"> $mafs1.and$mafs2.overlap.stat");
print "$mafs1\t$num1\t$overlap/$num1\n$mafs2\t$num2\t$overlap/$num2\n";
print OUT "$mafs1\t$num1\t$overlap/$num1\n$mafs2\t$num2\t$overlap/$num2\n";
close OUT;

sub readmafs{
    my $file=shift;
    my %h;
    my $num;
    open(IN,"$file");
    while(<IN>){
        chomp;
        next if (/chromo/);
        my @a=split(/\s+/);
        $h{$a[0]}{$a[1]}++;
        $num++;
    }
    close IN;
    return ($num,%h);
}
