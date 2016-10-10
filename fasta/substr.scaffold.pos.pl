#! /usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;

my $file="yak0803_v2.sca.break.fa.filter2K.fa";
my $chr=shift;
my $pos1=shift;
my $pos2=shift;
die "$0 chr pos_start pos_end\n"unless $pos2;

my $length=$pos2-$pos1+1;

open(OUT,"> $chr.$pos1.$pos2.fa");
my $fa=Bio::SeqIO->new(-file=>$file,-format=>'fasta');
while(my $seq=$fa->next_seq){
    my $id=$seq->id;
    my $seq=$seq->seq;
    if($id eq $chr){
        my $print=substr($seq,$pos1-1,$length);
        print OUT ">$id.$pos1.$pos2\n$print\n";
    }
}
close OUT;
