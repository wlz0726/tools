#!/usr/bin/perl -w
use strict;
use warnings;

my($fileIn,$copy_numbers,$mem,$proj_num)=@ARGV;
die("usage: <inCmd> <split_numbers> [mem] [proj_num]  (or CATwiwR(cattle) RATxdeR(BlindMoleRat) SHEtbyR(sheep) MOUwueR (zwy) AEAInte(test))\n")unless($copy_numbers);
#$proj_num||="CATwiwR";
$proj_num||="HUMdwcR";
$mem||="1";


`perl /home/wanglizhong/bin/000.split.sh.pl $fileIn $copy_numbers`;

my $outname=$fileIn;
$outname =~ s/(\.s\.\d+)$//;
my $dirout="z.$outname.z";
`mkdir $dirout`;


my @f=<$fileIn.s.*>;

foreach my $file(@f){
    open(Fo,"> $dirout/z.$file.pbs");
    print Fo "
#\$ -S /bin/sh
#\$ -e $dirout/z.$file.pbs.\$JOB_ID.e
#\$ -o $dirout/z.$file.pbs.\$JOB_ID.o
#\$ -l vf=${mem}G
#\$ -m n
#\$ -cwd
#\$ -P $proj_num
#\$ -q bc.q
";
    my $pwd=`pwd`;
    chomp $pwd;
    print Fo "cd $pwd\n";
    print Fo "date1=`date \"+%Y-%m-%d %H:%M:%S\"`; date1_sys=`date -d \"\$date1\" +%s`;echo \"start running ========= at \$date1\"\n\n";
    
    open(F,'<',$file) or die("$!: $file\n");
    while(<F>){
	print Fo "$_";
    }
    close(F);
    print Fo "date2=`date \"+%Y-%m-%d %H:%M:%S\"`; date2_sys=`date -d \"\$date2\" +%s`; interval=`expr \$date2_sys - \$date1_sys`; hour=`expr \$interval / 3600`;left_second=`expr \$interval % 3600`; min=`expr \$left_second / 60`; second=`expr \$interval % 60`; echo \"done  running ========= at \$date2 in \$hour hour \$min min \$second s\"\n";
    close(Fo);
    
}


`rm $fileIn.s.*`;
