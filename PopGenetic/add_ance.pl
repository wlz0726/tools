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
    my ($pos,$ance)=(split(/\s+/,$_))[1,-1];
     my $key="$pos";
     if($ance eq "N" || $ance eq "-") {$ance="0";}
     $hash{$key}="$ance $ance";
 }
while(<IN2>){
    chomp;
    my @t=split(/\s+/,$_);
    my ($chr,$pos)=(split(/\s+/,$_))[0,3];
    my $key="$pos";
    if($hash{$key}){
    print OUT "$_\t$hash{$key}\n";
#    print "$pos\t$hash{$key}\n";
}
}
close OUT;
close IN1;
close IN2;
