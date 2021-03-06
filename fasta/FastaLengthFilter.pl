#!/usr/bin/perl -w
use strict;
use warnings;
use Bio::SeqIO;
my ($fastaFile,$lengthLimit)=@ARGV;
die("$0: fastaFile lengthLimit\n") unless($lengthLimit);

my $in=Bio::SeqIO->new(-file=>"$fastaFile",-format=>'Fasta');
my $out=Bio::SeqIO->new(-file=>"> $fastaFile.Length.$lengthLimit.fa",-format=>'Fasta');
while(my $s =$in->next_seq()){
    my $seq=$s->seq;
    my $length=length($s->seq);
    next if($length < $lengthLimit);
    $out->write_seq($s);
}
