#!/usr/bin/perl
use warnings;
use strict;

if (@ARGV !=3) {
	print "perl $0 <in><random><out>\n";
	exit 0;
}
my ($in,$random,$out)=@ARGV;
if($in=~/.gz/) {open IN,"zcat $in|" or die $!;}  else{open IN,$in or die $!;}
open OUT,'>',$out or die $!;
my %hash=();
my $i=0;
my $sum=0;
while(<IN>){
    chomp;
    #my @a=split(/\s+/,$_);   
    #my @s=split(/\:/,$a[0]);
    my $sam=$_;
    my $str="";
    
    $hash{$sum}=$str;    
    $sum++;
}
if($sum<=$random) {
    foreach my $key (keys %hash){
	print OUT "$hash{$key}\n";
    }
}else{
    my %have=();
    while($i<$random){
	my $ram=int(rand($sum));
	if($have{$ram}) {next;} else{$have{$ram}=1;}
	print OUT "$hash{$ram}\n";    
        $i++;
    }
}

close OUT;
close IN;   
