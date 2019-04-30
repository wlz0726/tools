use strict;
use warnings;
use Bio::SeqIO;

my @in=<2*.fas>;
my %h;
for my $in (@in){
    $in=~/2\.(\S+)\.fas/;
    my $type=$1;
    my $fa=Bio::SeqIO->new(-file=>"$in",-format=>"fasta");
    while (my $seq=$fa->next_seq) {
        my $id=$seq->id;
        my $seq=$seq->seq;
        my $len=length($seq);
        $h{$id}{$type}{seq}=$seq;
        $h{$id}{$type}{len}=$len;
    }
}

open (O,">$0.list");
open (O1,">3.merge.fas");
for my $k (sort keys %h){
    print O "$k\t";
    print O1 ">$k\n";
    for my $k2 (sort keys %{$h{$k}}){
        print O "$k2:$h{$k}{$k2}{len}\t";
        print O1 "$h{$k}{$k2}{seq}";
    }
    print O "\n";
    print O1 "\n";
}
close O;
close O1;
