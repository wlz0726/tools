#!/usr/bin/env perl
use strict;
use warnings;
die "Usage: perl $0 <in.file> <in.file>\n" unless @ARGV eq 2;

my ($in1, $in2) = @ARGV;

open IN1, (($in1 =~ /\.gz$/) ? "gzip -dc $in1 |" : $in1) or die $!;
open IN2, (($in2 =~ /\.gz$/) ? "gzip -dc $in2 |" : $in2) or die $!;
while(<IN1>)
{
    my $line = <IN2>;
    if(/^>/)
    {
        tr/>/@/;
        my $header = $_;
        $_ = substr(<IN1>, 2);
        tr/0123./ACGTN/;
        my $atcg = $_;
        $_ = <IN2>;
        s/-1\b/0/g;
        s/^(\d+)\s*//;
        s/(\d+)\s*/chr($1+33)/eg;
        my $quality = $_;
        print "$header$atcg+\n$quality\n";
    }
}
close IN1;
