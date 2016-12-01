my ($FQ1_list)=@ARGV;
open (O, "> $FQ1_list.01.fastq-stats.pl.sh");
open(F,$FQ1_list);
while(<F>){
    chomp;
    next if(/^\s*$/);
    my $fq1=$_;
    my $dir;
    my $id;
    my $n3;
    
    if(/^(\S+)\/([^\/]+).1.filter.fq.gz$/){
        $dir=$1;
        $id=$2;
    }else{
        die "$_\n";
    }
    my $fq2="$dir/$id.2.filter.fq.gz";
    
    print O "fastq-stats $fq1 > $dir/$id.1.fq.stats\n";
    print O "fastq-stats $fq2 > $dir/$id.2.fq.stats\n";
}
close(F);
close(O);
