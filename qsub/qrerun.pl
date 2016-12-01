#!/usr/bin/perl -w
use strict;
use warnings;
my @in=@ARGV;
die "$0 job-ID1 job-ID2 job-ID3 ...\n"unless @in;
foreach my $in(@in){
    my $info=`qstat -j $in`;
    $info =~ /cwd:\s+([\S]+)/;
    my $dir=$1;
    $info =~ /stderr_path_list:\s+NONE:NONE:([\S]+)\.\$JOB_ID.e/;
    my $pbs="$dir/$1";
    
    #print "$pbs\n";
    `qdel $in`;# >> ~/test/log`;
    `rm $pbs.*e`;
    `rm $pbs.*o`;
    `cd $dir; qsub $pbs`;# >> ~/test/log`;
}

