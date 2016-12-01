#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=2 ) {
	print "perl $0 <in><out>\n";
	exit 0;
}
my ($in,$out)=@ARGV;
#if($in=~/.gz/) {open IN,"zcat $in|" or die $!;}  else{open IN,$in or die $!;}
open PED,"$in.ped" or die $!;
open MAP,"$in.map" or die $!;

open INFO,'>',"$out.info" or die $!;
open HAPS,'>',"$out.haps" or die $!;
open INFO2,'>',"$out.maker.info" or die $!;
my %hash=();
while(<PED>){
    chomp;
    my @s=split(/\s+/,$_);
    my($sam1,$sam2)=(@s)[0,1];
    shift@s;shift@s;shift@s;shift@s;shift@s;shift@s;
    my $str=join "\t",@s;
    $str=~ tr/ACGT/1234/;
    my@tmp=split(/\s+/,$str);
    my ($hap1,$hap2)=(@tmp)[0,1];
    my $i=2;
    while($i< scalar@tmp){
        $hap1.="\t$tmp[$i]";
        $i+=2;
    }
    $i=3;
    while($i< scalar@tmp){
        $hap2.="\t$tmp[$i]";
        $i+=2;
    }
    
    print HAPS "$sam2\t$sam2\t$hap1\n";
    print HAPS "$sam2\t$sam2\t$hap2\n";
}

my $i=1;
while(<MAP>){
chomp;
my @s=split(/\s+/,$_);
my $id=$s[-1];
my $marker="Marker$i";
print INFO "$marker\t$id\n";
print INFO2 "$s[1]\t$id\n";
$i++;
}

close PED;
close MAP;
close INFO;   
close HAPS;
close INFO2;
