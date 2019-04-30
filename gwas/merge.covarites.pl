#!/usr/bin/perl
use strict;
use warnings;

my $age_gender=shift;
my $pca=shift;
my $outfile=shift;
my $pc_number=shift;

die "$0 <age_gender.txt> <gcta.eigenvec> <outfile> [PC_number]\n"unless $outfile;
$pc_number||=10;

my %h;
open(I,$age_gender);
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $h{$a[0]}="$a[1] $a[2]";
}
close I;

open(I,"$pca");

# print head
open(O,"> $outfile");
print O "FID IID AGE GENDER";
for(my $i=1;$i<=$pc_number;$i++){
    print O " C$i"
}
print O "\n";

# print 
while(<I>){
    chomp;
    my @a=split(/\s+/);
    my $id=$a[0];
    if(exists $h{$id}){
	print O "$id $id $h{$id}";
	for(my $i=1;$i<=$pc_number;$i++){
	    my $j=$i+1;
	    print O " $a[$j]"
	}
	print O "\n";
    }else{
	die "$_\n";
    }
}
close I;
close O;
