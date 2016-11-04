#!/usr/bin/perl
use strict;
use warnings;

my $file=shift;
open(IN, "$file");
open(OUT, "> $file.fas");
my $before=0;
while(<IN>){
    chomp;
    if((/^@(scaffold\d+\_\d)/) || (/^@(C\d+\_\d)/)){
        print OUT ">$1\n";
        $before=1;
        next;
    }elsif(/^\+$/){
        $before=0;
        next;
    }
    if($before == 1){
        print OUT "$_\n";
        next;
    }
}
close IN;
close OUT;
