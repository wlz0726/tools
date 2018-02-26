#!/usr/bin/perl -w
use strict;
use warnings;

my $dir=shift;
my $job_number=`ls $dir/*pbs|wc -l`; chomp $job_number;
my $rand=int(rand(1000000000));
die "$0 z.01.MSMC.RelativeCrossCoalescenceRate.pl.1.bed.sh.z\n"unless $dir;
`grep 'done  running =========' $dir/*o > ./tmmmmmmmp.$rand`;
my %h;
my $line=`cat ./tmmmmmmmp.$rand|wc -l`; chomp $line;
if($line==0){
    print "sb.pl $dir\n";
}elsif($line==1 && $job_number==1){
    open(IN,"./tmmmmmmmp.$rand");
    my $content=<IN>;
    close IN;
    if($content =~ /done  running/){
	print "all finished!\n";
    }else{
	print "erro!\n";
    }
}else{
    open(I,"./tmmmmmmmp.$rand");
    while(<I>){
	chomp;
	if(/(.*.pbs).(\d+).o\:done\s+running/){
	    #print $1,"\n";
	    $h{$1}=$2;
	}else{
	    print "$_\n";
	}
    }
    close I;
    
    
    my $m=0;
    my @f=<$dir/*pbs>;
    open(O,"> $dir.sh");
    foreach my $f(@f){
	if(exists $h{$f}){
	    next;
	}
	$m++;
	print O "qsub $f \n";
    }
    close O;
    if($m<1){
	print "all finished!\n";
	`rm $dir.sh`;
    }else{
	print "$m need to be rerun by:\n\nsh $dir.sh\n";
    }
}
`rm ./tmmmmmmmp.$rand`;
