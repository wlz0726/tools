#!/usr/bin/perl
use strict;
use warnings;

# Input and usage 
my ($ref,$bamlist,$vcflist,$outdir)=@ARGV;
die "
Usage:
       perl $0 <ref> <bamlist> <vcflist> [outdir]

       ref: reference genome with .fai index
   bamlist: 4 cols: 'Population Sample_id Average_depth file.bam'
            One populations with 1~4 individuals (2~8haplotypes); One individual perl line; 
   vcflist: 2 cols: '/path/to/Chr1.vcf.gz Chr1'
   
    outdir: Output directory [$0.out]

"unless $vcflist;

# default set
$outdir ||="$0.out";

### configure =========================================================
my $vcftools='/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools';
my $samtools='/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/samtools';
my $bcftools='/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/bcftools/bcftools';
my $msmctools='/home/wanglizhong/software/msmc/msmc-master/tools';
my $msmc='/home/wanglizhong/software/msmc/msmc-master/build/msmc';
my $python='/opt/blc/python-3.1.2/bin/python3.1';
my $set_python='export LD_LIBRARY_PATH=/opt/blc/python-3.1.2/lib:$LD_LIBRARY_PATH';
### ===================================================================

# read chr info in vcflist
my %chr;
open(CHR,"$vcflist");
while(<CHR>){
    chomp;
    my @a=split(/\s+/);
    $chr{$a[1]}=$a[0]; # chr_name  /path/to/vcf.vcf.gz
}
close CHR;

# read bamlist
# step1 output bed.sh vcf.sh
my %pop;
my $pop=0;
my $sample_size=0;
open(O1,"> $0.1.bed.sh");
open(O2,"> $0.1.vcf.sh");
open(I1,"$bamlist");
while(<I1>){
    chomp;
    my @a=split(/\s+/);
    $sample_size++;
    if($pop eq 0){
	$pop=$a[0];
    }
    my ($id,$depth,$bam)=($a[1],$a[2],$a[3]);
    $pop{$a[1]}++;
    #print "$id\t$depth\tbam\n";
    my $outpath="$outdir/01.Input/$pop/$id";
    `mkdir -p $outpath`unless -e $outpath;
    foreach my $chr(sort keys %chr){
	print O1 "$set_python; $samtools mpileup -q 20 -Q 20 -C 50 -u -r $chr -P ILLUMINA -f $ref $bam |$bcftools view -cgI - | $python $msmctools/bamCaller.py $depth $outpath/$id.$chr.mask.bed > $outpath/$id.$chr.raw.vcf;\n";
	print O2 "$vcftools --gzvcf $chr{$chr} --indv $id --chr $chr --max-missing 1 --recode --out $outpath/$id.$chr;\n";
    }
}
close I1;
close O1;
close O2;

my @pop=keys %pop;
open(O3,"> $0.2.Merge.sh");
open(O4,"> $0.3.Ne.sh");
foreach my $ind(keys %pop){
    my $name=$pop;
    my $outpath2="$outdir/02.Combine/$name";
    `mkdir -p $outpath2` unless -e $outpath2;
    my $outpath3="$outdir/03.Out";
    `mkdir -p $outpath3` unless -e $outpath3;
        
    # merge individuals
    my @mergeout;
    foreach my $chr(sort keys %chr){
	my @mask;
	my @vcffiles;
	my $outfile="$outpath2/$pop.$chr.txt";
	push(@mergeout,$outfile);
	foreach my $sample_id(@pop){
	    my $mask="$outdir/01.Input/$pop/$sample_id/$sample_id.$chr.mask.bed";
	    my $vcf="$outdir/01.Input/$pop/$sample_id/$sample_id.$chr.recode.vcf";
	    push(@mask,$mask);
	    push(@vcffiles,$vcf);
	}
	# step2: merge genotype
	print O3 "$set_python; $python $msmctools/generate_multihetsep.py --mask ",join(" --mask ",@mask)," ",join(" ",@vcffiles),"> $outfile;\n";
    }
    # step4: run msmc to estimate Ne
    # You might want to reduce the resolution for some test runs to 30 segments (using e.g. -p 8*1+11*2), 
    # or even 20 segments (using e.g. -p 20*1)
    if($sample_size eq 1){
        # For running on only one individual (two haplotypes), you should leave
        #   out the flag --fixedRecombinatio (-R )
        print O4 "$msmc -o $outpath3/$name.ne.2haps -i 50 -t 10 -p '15*1+15*2' ";
    }else{
	my $hap_num=2*$sample_size;
	print O4 "$msmc -R -o $outpath3/$name.ne.$hap_num","haps -i 50 -t 10 -p '15*1+15*2' ";
    }
    print O4 join(" ",@mergeout);
    print O4 "\n";
}
close O3;
close O4;
