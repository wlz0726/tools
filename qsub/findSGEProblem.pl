#!/usr/bin/perl -w

use strict;
use warnings;

my $dir=shift;

die "$0 z.pbs.dir.name > out.sh"unless $dir;
my @out=<$dir/*out>;
my %pbs;
foreach my $out(@out){
    $out =~ /(.*\/.*)\.\d+.out/;
    #print "$1\n";
    my $pbs="$1.pbs";
    #print "$out\t$pbs\n";die;
    $pbs{$pbs}++;
}


my @f=<$dir/*pbs>;
foreach my $f(@f){
    next if(exists $pbs{$f});
    print "qsub $f;\n";
    
}
