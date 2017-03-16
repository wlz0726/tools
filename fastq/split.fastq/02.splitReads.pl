my @in=@ARGV;
die "$0 SRR1101035_1.fastq.gz SRR1101036_1.fastq.gz ..\n"unless $ARGV[0];

my $bin="100000000"; # reads number in each split file

open(O,"> $0.sh");
foreach my $in(@in){
        
    $in =~ /(.*)_1.fastq.gz/;
    my $out="$1.split";
    `mkdir $out`unless -e $out;
    
    my $in2="$1\_2.fastq.gz";
    print O "perl splitReads.pl $1 $in $in2 $out $bin > $out/$1.log;\n";
}
close O;
