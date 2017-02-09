my $outdir='/home/wanglizhong/project/01.cattle.CATwiwR/1608.MSMC.cattle.Pipeline/Ne_8haps/group2';#'/ifshk5/PC_HUMAN_EU/USER/wanglizhong/project.hk/1608.MSMC.cattle.Pipeline/Ne_8haps/group2';
`mkdir -p $outdir`;
my $ref='/ifshk4/BC_COM_P5/F13HTSNWKF0106/CATwiwR/zhuwenjuan/step1.data/reference/UMD3.1.fasta';#'/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta';
my $bin='/home/wanglizhong/project/01.cattle.CATwiwR/1608.MSMC.cattle.Pipeline/Ne_8haps/bin';#'/ifshk5/PC_HUMAN_EU/USER/wanglizhong/project.hk/1608.MSMC.cattle.Pipeline/Ne_8haps/bin';
my $msmc_ne="/home/wanglizhong/project/01.cattle.CATwiwR/1608.MSMC.cattle.Pipeline/Ne_8haps/pipeline_msmc_Ne.pl";

open(O,"> $0.0.sh");
open(O1,"> $0.1.sh");
open(O2,"> $0.2.sh");
open(O3,"> $0.3.sh");
my @f=(BRM,FLV,GIR,HOL,JBC,JER,LIM,NEL,QCC,RAN);
foreach my $i(@f){
    my $bamlist="$bin/$i.bamlist";
    my $vcflist="$bin/$i.vcflist";
    `mkdir -p $outdir/$i`;
    print O "cd $outdir;perl $msmc_ne -bamlist $bamlist -ref $ref -vcflist $vcflist -depth $bamlist -chrlist $bin/chrlist -o $outdir/$i;\n";
    print O1 "cd $outdir/$i;cp $bin/qsub.sh .;cat step1_bedfile.sh step1_vcffile.sh >run.sh;sh qsub.sh;\n";
    
    print O2 "cd $outdir/$i;cp $bin/qsub.sh .;cp step2_msmc_inputfile.sh run.sh;sh qsub.sh;\n";
    print O3 "cd $outdir/$i; qsub -cwd -l vf=80G -q supermem.q -P st_supermem step3_msmc_Ne.sh;\n";
}
close O;
close O1;
close O2;
close O3;

