use strict;
use warnings;

my $in=shift or die "input\n";
my $outdir="03.split_by_chr";
$in=~/(\w+)\.g.vcf.gz$/;
my $ind=$1;
open (O1,">$0.$ind.tabix.sh");
open (F,"zcat $in | ");
my $info;
my $old="NA";
while (<F>) {
    chomp;
    if (/^#/){
        $info .= "$_\n";
    }
    next if /^#/;
    my @a=split(/\t/,$_);
    if ($old eq 'NA'){
        print O1 "/home/share/users/yangyongzhi2012/tools/samtools/tabix-0.2.6/tabix -p vcf $outdir/$ind.$a[0].g.vcf.gz\n";
        open (O,"| /home/share/users/yangyongzhi2012/tools/samtools/tabix-0.2.6/bgzip -c  > $outdir/$ind.$a[0].g.vcf.gz") || die "$!";
        print O "$info";
        $old=$a[0];
    }elsif ($old ne $a[0]){
        close O;
        print O1 "/home/share/users/yangyongzhi2012/tools/samtools/tabix-0.2.6/tabix -p vcf $outdir/$ind.$a[0].g.vcf.gz\n";
        open (O,"| /home/share/users/yangyongzhi2012/tools/samtools/tabix-0.2.6/bgzip -c  >$outdir/$ind.$a[0].g.vcf.gz")||die"$!";
        print O "$info";
        $old=$a[0];
    }else{
        
    }
    print O "$_\n"
}
close F;
close O;
close O1;
