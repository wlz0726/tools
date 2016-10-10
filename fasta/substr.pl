#! /usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;

my $file=shift;
my $pos=shift;
die "$0 fasta pos\n"unless $pos;

my $fa=Bio::SeqIO->new(-file=>$file,-format=>'fasta');

while(my $seq=$fa->next_seq){
    my $id=$seq->id;
    my $seq=$seq->seq;
    my $print=substr($seq,$pos-1,5);
    print "$print";
}
#close O;
