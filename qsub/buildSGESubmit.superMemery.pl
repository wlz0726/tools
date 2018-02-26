#!/usr/bin/perl -w

use strict;
use warnings;

my($fileIn,$mem,$ncpus)=@ARGV;
die("usage: inCmd mem num_of_cpu \n")unless($mem);
#ProjectNum[ CATwiwR(cattle) or AEAInte(test) or st_supermem] queue[bc.q OR bc_supermem.q]\n")unless($proj_num);
$ncpus||="5";

my $name="z.$fileIn.SuperMem";
my $dirout="z.$fileIn.SuperMem";

mkdir($dirout)unless(-e $dirout);

my @cmd;
open(F,'<',$fileIn) or die("$!: $fileIn\n");
while(<F>){
    chomp;
    push(@cmd,$_);
}
close(F);

my $i=0;
foreach my $cmd(@cmd){
    $i++;
    my $fileOut="$dirout/$name-$i.pbs";
    open(Fo,'>',$fileOut) or die("$!: $fileOut\n");
    print Fo "#\$ -S /bin/sh
#\$ -e $dirout/$name-$i.pbs.\$JOB_ID.e
#\$ -o $dirout/$name-$i.pbs.\$JOB_ID.o
#\$ -l vf=${mem}G
#\$ -l ncpus=${ncpus}
#\$ -m n
#\$ -cwd
#\$ -P st_supermem
#\$ -q supermem.q
##-q supermem.q\@supermem-0-0 
# 1T:   supermem-0-0
# 250G: supermem-0-2 supermem-0-3 supermem-0-4

";
    my $pwd=`pwd`;
    chomp $pwd;
    print Fo "cd $pwd\n\n";
    print Fo "date1=`date \"+%Y-%m-%d %H:%M:%S\"`; date1_sys=`date -d \"\$date1\" +%s`;echo \"start running ========= at \$date1\"\n\n";

    print Fo "$cmd\n\n";
    print Fo "date2=`date \"+%Y-%m-%d %H:%M:%S\"`; date2_sys=`date -d \"\$date2\" +%s`; interval=`expr \$date2_sys - \$date1_sys`; hour=`expr \$interval / 3600`;left_second=`expr \$interval % 3600`; min=`expr \$left_second / 60`; second=`expr \$interval % 60`; echo \"done  running ========= at \$date2 in \$hour hour \$min min \$second s\"\n";
    
    close(Fo);
}
