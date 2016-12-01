#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
    chomp;
    next if(/^\s*$/);
    if (/^@/){
        print "$_\n";
        next;
    }
    my @a=split(/\s+/,$_);
    my $flag=$a[1];
    next if($flag & 4 );    # unmapped
    next if($flag & 256 );  # the alignment is not primary
    next if($flag & 512 );  # the read fails platform/vendor quality checks
    next if($flag & 2048 ); # supplementary alignment
    print "$_\n";
}
