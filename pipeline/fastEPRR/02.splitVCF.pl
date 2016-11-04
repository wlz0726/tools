# you may want to change this
my @chr=(1..29); 
my $snpdir="/ifshk5/PC_HUMAN_EU/USER/wanglizhong/project.hk/01.SNP.phase/001.beagle.pl.out/0.5";
# ---------------------------

open(OUT,"> $0.1.sh");
open(O2,"> $0.2.sh");
open(O3,"> $0.3.sh");
open(O4,"> $0.4.sh");
open(O5,"> $0.5.sh");
my @f=<Pop_*/*.txt>;
foreach my $f(@f){
    $f =~/(.*)\/(.*).txt/;
    my $dir=$1;
    my $id=$2;
    `mkdir $dir/vcf`unless (-e "$dir/vcf");
    `cp bin/*pl $dir`;
    print O2 "cd $dir; perl 02.fastEPRR.pl; perl /ifshk5/PC_HUMAN_EU/USER/wanglizhong/bin/buildSGESubmit.pl 02.fastEPRR.pl.step1.sh 0.6;perl /ifshk5/PC_HUMAN_EU/USER/wanglizhong/bin/submit.pl z.02.fastEPRR.pl.step1.sh.z; cd ..;\n";
    # need this when deal genome with scaffolds
    # print O3 "cd $dir; perl remove_line1.pl;cd ..;";
    print O3 "cd $dir; perl 03.FastEPRR.step2and3.pl; perl /ifshk5/PC_HUMAN_EU/USER/wanglizhong/bin/buildSGESubmit.pl 03.FastEPRR.step2and3.pl.step2.sh 1; perl /ifshk5/PC_HUMAN_EU/USER/wanglizhong/bin/submit.pl z.03.FastEPRR.step2and3.pl.step2.sh.z; cd ..;\n";
    print O4 "cd $dir; sh 03.FastEPRR.step2and3.pl.step3.sh;\n";
    foreach my $chr(@chr){
	my $snp="$snpdir/$chr.vcf.gz";
	print OUT "/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools --gzvcf $snp --keep $f --non-ref-ac-any 1 --recode -c | gzip -c > $dir/vcf/$chr.vcf.gz;\n";
    }
    print O5 "cd $dir; perl 04.transFormat.pl;perl 05.seperate.pl;cd ..;\n";
}
close OUT;
close O2;
close O3;
close O4;
close O5;
