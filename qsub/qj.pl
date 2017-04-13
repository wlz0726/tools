#!/usr/bin/perl -w
use strict;
use warnings;

my @in=@ARGV;
die "$0 job-ID1 job-ID2 ...\n"unless $ARGV[0];
foreach my $in(@in){
    `qstat -j $in > .tmp`;
    print "$in\n";
    open(I,".tmp");
    while(<I>){
	chomp;
	if(/cwd:\s+(.*)/){
	    print "$1\n";
	}
	if(/script\_file:\s+(.*)/){
	    print "qsub $1\n";
	}
	if(/usage\s+1:\s+(.*)/){
	    print "$1\n";
	}
	if(/hard resource_list:\s+(.*)/){
	    print "$1\n";
	}
	if(/hard_queue_list:\s+(.*)/){
	    print "$1\n";
	}
    }
    close I;
    print "\n";
}
`rm .tmp`;
