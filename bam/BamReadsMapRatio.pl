#! /usr/bin/perl
use strict;
use warnings;

# count mapped reads number and mapping rate
my $file=shift;;
my $name=(split(/\/,$file/))[-1];
my $id=(split(/\./,$name))[0];

my $all=0;
my $aln=0;


open(F, "/home/wanglizhong/bin/samtools view $file |");
while(<F>){
    chomp;
    next if(/^\@SQ/);
    my @a=split(/\s+/);
    if($1 & 4){
	# unmapped
    }else{
	$aln++;
    }
    $all++;
}
close F;
my $per=$aln/$all;
print "$id\t$aln\t$all\t$per\n";
