#!/usr/bin/perl -w
use strict;
use warnings;
use Bio::SeqIO;
my ($fastaFile,$outFile)=@ARGV;
die("$0: InFasta OutFasta\n") unless($outFile);

my @chr=(1..19,"X","Y","MT");
my %chr;
undef @chr{@chr};

my $in=Bio::SeqIO->new(-file=>"$fastaFile",-format=>'Fasta');
my $out=Bio::SeqIO->new(-file=>"> $outFile",-format=>'Fasta');
while(my $s =$in->next_seq()){
    my $id= $s->id;
    my $seq=$s->seq;
    if(exists $chr{$id}){
	$out->write_seq($s);
    }
}
