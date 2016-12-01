#!/usr/bin/perl -w
my $reference="00.ref/Trinity.fasta";
my $FQ1_list="00.reads.list";
my $OutDir="bowtie2";

my %sample;
`mkdir $OutDir`unless -e "$OutDir";
open(O,'>',"01.$OutDir.pl.sh");

open(F,$FQ1_list);
while(<F>){
    chomp;
    next if(/^\s*$/);
    my $fq1=$_;
    my $dir;
    my $id;
    my $fq2;
    
    
    if(/^(\S+)\/([^\/]+).1.filter.fq.gz$/){
        $dir=$1;
        $id=$2;
        $fq2="$dir/$id.2.filter.fq.gz";
    }elsif(/^(\S+)\/([^\/]+).1.fq.gz$/){
        $dir=$1;
        $id=$2;
        $fq2="$dir/$id.2.fq.gz";
    }elsif(1){
        die "$_\n";
    }
    
    /^(\S+)\/([^\/]+\.T(\d)).1.filter.fq.gz$/;
    if($3==0){
        print O "bowtie2 -q --phred64 --end-to-end --no-unal -p 30 -x $reference -1 $fq1 -2 $fq2 | ./00.01.filter.duplicate.v2.pepiline.pl |samtools view -bS -o $OutDir/$id.bam - ;";
    }elsif($3==1){
        print O "bowtie2 -q --phred33 --end-to-end --no-unal -p 30 -x $reference -1 $fq1 -2 $fq2 | ./00.01.filter.duplicate.v2.pepiline.pl |samtools view -bS -o $OutDir/$id.bam - ; ";
    }else{
        die;
    }
    print O "samtools sort $OutDir/$id.bam $OutDir/$id.sort\n";
}
close(F);
close(O);
