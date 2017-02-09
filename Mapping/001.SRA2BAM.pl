my $SRP_list=shift;
die "$0 <SRP_list.list> 
SRP_list: 
/ifshk1/pub/database/ftp.ncbi.nih.gov/sra/sra-instant/reads/ByStudy/sra/SRP/SRP001/SRP001574/SRR032564/SRR032564.sra
#/ifshk1/pub/database/ftp.ncbi.nih.gov/sra/sra-instant/reads/ByStudy/sra/SRP/SRP001/SRP001574/SRR035526/SRR035526.sra

use # to skip

\n"unless $SRP_list;




my $outdir="$0.out";
`mkdir $outdir`;
`mkdir -p $outdir/tmp`;
$SRP_list =~ /(.*).list/;
my $name=$1;
my $head="NA";

#=========== path set
my $bwa="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/bwa-0.7.10/bwa";
my $samtools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-1.2/samtools-1.2/bin/samtools";
my $picard="/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/gatk/picard/picard.jar";
my $gatk="/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/gatk/GenomeAnalysisTK.jar";
my $java="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/java/jre1.8.0_45/bin/java";
my $javahome="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/java/jre1.8.0_45";
my $fastqdump="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/sratoolkit-2.3.4/bin/fastq-dump";
#=========== where you may want to change
my $ref="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta";
#===========

open(I,"$SRP_list");
open(O1,"> $0.$name.1.sra2fq.sh");
open(O2,"> $0.$name.2.bwa.sh");
open(LIST,"> $outdir/$SRP_list.bamlist");
open(M,"> $0.$name.3.merge.sh");
while(<I>){
    next if(/^\#/);
    chomp;
    my $sra=$_;
    /\/([\w\d]+)\/[\w\d]+\/([\w\d]+).sra$/;
    my $id1=$1;
    my $id2=$2;
    `mkdir $outdir/$id1`;
    my $read1="$outdir/$id1/$id2\_1.fastq.gz";
    my $read2="$outdir/$id1/$id2\_2.fastq.gz";
    
    if($head eq "NA"){
	$head = "$outdir/$id1/$id2.realn.bam";
    }
    
    print O1 "$fastqdump --split-3 --gzip -O $outdir/$id1 $sra; \n";
    print O2 "$bwa mem -t 30 -M -R \'\@RG\\tID:$name\\tLB:$name\\tSM:$name\\tPL:Illumina\\tPU:Illumina\\tSM:$name\\t\' $ref $read1 $read2|$samtools sort -O bam -T $outdir/tmp/$id2 -o $outdir/$id1/$id2.sort.bam; $samtools index $outdir/$id1/$id2.sort.bam;  ";
    print O2 "export JAVA_HOME=$javahome; $java -Xmx5g -jar $picard MarkDuplicates INPUT=$outdir/$id1/$id2.sort.bam OUTPUT=$outdir/$id1/$id2.rmdup.bam METRICS_FILE=$outdir/$id1/$id2.dup.txt REMOVE_DUPLICATES=true; $samtools index $outdir/$id1/$id2.rmdup.bam;  ";
    print O2 "$java -jar $gatk -nt 15 -R $ref -T RealignerTargetCreator -o $outdir/$id1/$id2.realn.intervals -I $outdir/$id1/$id2.rmdup.bam 2>$outdir/$id1/$id2.realn.intervals.log;   ";
    print O2 "$java -jar $gatk -R $ref -T IndelRealigner -targetIntervals $outdir/$id1/$id2.realn.intervals -o $outdir/$id1/$id2.realn.bam -I $outdir/$id1/$id2.rmdup.bam 2>$outdir/$id1/$id2.realn.bam.log;\n";
    print LIST "$outdir/$id1/$id2.realn.bam\n";
}
close I;
close O1;
close O2;
close LIST;


print M "$samtools merge -b $outdir/$SRP_list.bamlist -h $head -c -p -f $outdir/$name.bam; $samtools index $outdir/$name.bam; \n ";
close M;
