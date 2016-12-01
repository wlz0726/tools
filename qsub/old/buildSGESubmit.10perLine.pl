#!/usr/bin/perl -w

use strict;
use warnings;

my($fileIn,$mem,$proj_num)=@ARGV;
die("usage: inCmd mem ProjectNum[ CATwiwR(cattle) or AEAInte(test)] \n")unless($proj_num);

my $name="z.$fileIn";
my $dirout="z.$fileIn";


mkdir($dirout)unless(-e $dirout);

my @cmd;
open(F,'<',$fileIn) or die("$!: $fileIn\n");
while(<F>){
    chomp;
    push(@cmd,$_);
}
close(F);

my $i=0;
#foreach my $cmd(@cmd){
for(my $i=0;$i<@cmd;$i+=2){
    my $j=$i+1;
    my $fileOut="$dirout/$name-$j.pbs";
    open(Fo,'>',$fileOut) or die("$!: $fileOut\n");
    print Fo "
#\$ -S /bin/sh
#\$ -e $dirout/$name-$i.\$JOB_ID.err
#\$ -o $dirout/$name-$i.\$JOB_ID.out
#\$ -l vf=${mem}G
#\$ -m n
#\$ -cwd
#\$ -P $proj_num
#\$ -q bc.q
";
    my $pwd=`pwd`;
    chomp $pwd;
    print Fo "cd $pwd\n";
    print Fo "$cmd[$i]\n";
    if(exists $cmd[$j]){
	print Fo "$cmd[$j]\n\n";
    }
    close(Fo);
}
