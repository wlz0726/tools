my @in=@ARGV;
die "$0 SRR1101035_1.fastq.gz SRR1101036_1.fastq.gz ..\n"unless $ARGV[0];
open(O,"> $0.sh");
foreach my $in(@in){
    print O "perl count.reads.pl $in > $in.readsNum;\n";
}
close O;
