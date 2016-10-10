#! /usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;

my $file=shift;
my $outfile="$file.filter2K.fa";
open(O, "> $outfile");
my $fa=Bio::SeqIO->new(-file=>$file,-format=>'fasta');

while(my $seq=$fa->next_seq){
    my $id=$seq->id;
    my $seq=$seq->seq;
    my $length= length($seq);
    next if ($length < 2000);
    print O ">$id\n$seq\n";
}
close O;
