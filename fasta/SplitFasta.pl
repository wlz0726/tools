#!/usr/bin/perl -w
use strict;
use warnings;
use Bio::SeqIO;

my $fastaFile=shift;
die("$0: fastaFile \n") unless($fastaFile);
my $out="$fastaFile.split";
`mkdir $out`;

my $in=Bio::SeqIO->new(-file=>"$fastaFile",-format=>'Fasta');
while(my $s =$in->next_seq()){
    my $id=$s->id;
    my $seq=$s->seq;
    open(O1,"> $out/$id.fa");
    print O1 ">$id\n$seq\n";
    close O1;
}

