#!/usr/bin/perl -w
use strict;
use warnings;
use Bio::SeqIO;
my $fastaFile=shift;
die("$0: fastaFile\n") unless($fastaFile);
my %seqs;
my $totallen=0;
my $totalN=0;
my $in=Bio::SeqIO->new(-file=>"$fastaFile",-format=>'Fasta');
while(my $s =$in->next_seq()){
    my $seq=$s->seq;
    $seq=~s/[^nN]//g;
    $totalN+=length($seq);
    $seqs{$s->id}{'len'}=length($s->seq);
    $totallen+=length($s->seq);
}
undef $in;
my @seqsArray=sort {$seqs{$b}{'len'} <=> $seqs{$a}{'len'}} keys %seqs;

print "total    :\t",scalar(@seqsArray),"(seqs), ",$totallen,"(bases), average length: ",$totallen/@seqsArray,"\n";
print "longest  :\t", $seqsArray[0],"(name)\t",$seqs{$seqsArray[0]}{'len'},"(length)\n";
print "shortest :\t",$seqsArray[$#seqsArray],"(name)\t", $seqs{$seqsArray[$#seqsArray]}{'len'},"(length)\n";
my $len=0;
my ($fn50,$fn90)=(1,1);
my $num=0;
foreach my $s(@seqsArray){
    $len+=$seqs{$s}{'len'};
    $num++;
    if($len/$totallen>0.5 && $fn50){
        print "n50  =\t",$seqs{$s}{'len'},"\t";
        print "number=$num\n";
        $fn50=0;
    }
    elsif($len/$totallen>0.9 && $fn90){
        print "n90  =\t",$seqs{$s}{'len'},"\t";
        print "number=$num\n";
        $fn90=0;
        last;
    }
}
print "totalN=$totalN\t";
my $percent=$totalN/$totallen;
print "N percent:$percent\n";
