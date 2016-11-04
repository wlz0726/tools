#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=3 ) {
	print "perl $0 <in1><in2><out>\n";
	exit 0;
}
my ($in1,$in2,$out)=@ARGV;
   if($in1=~/.gz/) {open IN1,"zcat $in1|" or die $!;}  else{open IN1,$in1 or die $!;}
   if($in2=~/.gz/) {open IN2,"zcat $in2|" or die $!;}  else{open IN2,$in2 or die $!;}
   
open OUT,'>',$out or die $!;
my %hash=();
while(<IN1>){
    chomp;
    my @t=split(/\s+/,$_);
    my ($sam,$pop)=(split(/\s+/,$_))[1,3];
     my $key=$sam;
     if($sam=~/SRR/) {$sam="SRR".substr($sam,length($sam)-2,2)}
#     $pop=substr($pop,0,1);
     $hash{$key}="$sam-$pop";
}
while(<IN2>){
    chomp;
    my @t=split(/\s+/,$_);
    my $key=(@t)[0];
    print OUT "$hash{$key}\t$hash{$key}\t0\t0\t0\t1\n";
}
close OUT;
close IN1;
close IN2;
