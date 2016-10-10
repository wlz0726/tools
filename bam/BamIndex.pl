#!/usr/bin/perl -w
my $list=shift;
open(IN,"$list");
my @file=<IN>;
foreach my $f(@file){
    chomp $f;
    print "samtools index $f\n";
}
