my $ref=shift;
my $dir=shift;
die "
$0 <reference> <directory>

Directory like this:
\$ ls directory
SampleA_1.fq.gz SampleA_2.fq.gz SampleB_1.fq.gz SampleB_2.fq.gz ...
\n"unless $dir;

my @read1=<$dir/*1.fastq.gz>;
#===========
my $bwa="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/bwa-0.7.10/bwa";
my $samtools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-1.2/samtools-1.2/bin/samtools";
my $picard="/home/wanglizhong/software/gatk/picard/picard.jar";
my $gatk="/home/wanglizhong/software/gatk/GenomeAnalysisTK.jar";
my $java="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/java/jre1.8.0_45/bin/java";
my $javahome="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/java/jre1.8.0_45";
#my $ref="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta";
my $outdir="$0.out";
`mkdir -p $outdir/tmp`;
`mkdir tmp`;
#===========
# all in one shell script;
open(O,"> $0.sh");
foreach my $read1(@read1){
    $read1 =~ /(.*\/(.*))_1.fastq.gz/;
    my $read2="$1\_2.fastq.gz";
    my $id=$2;
    print O "$bwa mem -t 15 -R \'\@RG\\tID:$id\\tLB:$id\\tSM:$id\\tPL:Illumina\\tPU:Illumina\\tSM:$id\\t\' $ref $read1 $read2|$samtools sort -O bam -T $outdir/tmp/$id -o $outdir/$id.sort.bam; $samtools index $outdir/$id.sort.bam;  ";
    print O "export JAVA_HOME=$javahome; $java -Xmx3g -Djava.io.tmpdir=tmp -XX:MaxPermSize=512m -XX:-UseGCOverheadLimit -jar $picard MarkDuplicates INPUT=$outdir/$id.sort.bam OUTPUT=$outdir/$id.rmdup.bam METRICS_FILE=$outdir/$id.dup.txt REMOVE_DUPLICATES=true MAX_FILE_HANDLES=1000 TMP_DIR=tmp VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true; ";
    print O "$java -Xmx4g -Djava.io.tmpdir=tmp -XX:MaxPermSize=512m -XX:-UseGCOverheadLimit -jar $gatk -nt 15 -R $ref -T RealignerTargetCreator -o $outdir/$id.realn.intervals -I $outdir/$id.rmdup.bam 2>$outdir/$id.realn.intervals.log;   ";
    print O "$java -Xmx4g -Djava.io.tmpdir=tmp -XX:MaxPermSize=512m -XX:-UseGCOverheadLimit -jar $gatk -R $ref -T IndelRealigner -targetIntervals $outdir/$id.realn.intervals -o $outdir/$id.realn.bam -I $outdir/$id.rmdup.bam -maxInMemory 300000 2>$outdir/$id.realn.bam.log;\n";
}
close O;

