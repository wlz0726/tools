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
    #my $seq=$s->seq;
    my $out=Bio::SeqIO->new(-file=>"> $out/$id.fa",-format=>'Fasta');
    $out->write_seq($s);
}

