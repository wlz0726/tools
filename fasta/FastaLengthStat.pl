#!/usr/bin/perl -w
use strict;
use warnings;
use Bio::SeqIO;
my $fastaFile=shift;
open(O1, "> $fastaFile.Length.stat.list");
die "$0 ref.fa\n"unless $fastaFile;

my $in=Bio::SeqIO->new(-file=>"$fastaFile",-format=>'Fasta');
while(my $s =$in->next_seq()){
    my $id=$s->id;
    my $seq=$s->seq;
    my $length=length($s->seq);
    print O1 "$id\t$length\n";
}
close O1;
