#!/usr/bin/perl -w
use strict;
use warnings;
my ($start,$end)=@ARGV;
die "$0 job-ID_start job-ID_end\n"unless $end;

my $tmp;
for (my $i=$start;$i<=$end;$i++){
    $tmp.=" $i";
}
`qdel $tmp`;
