use strict;
use warnings;

my $out="$0.out";
`mkdir $0.out` if (! -e "$out");
for my $in (</home/pool/users/yangyongzhi2012/Ostrya_resequnce/04.deleterious_mutations/Ore_ref/Second_try_dog/02.CountReadFoursite_fltRepeat/00.pos.pl.out/*sites>){
    chomp $in;
    $in=~/00.pos.pl.out\/(\w+)\.(\d+-\d+)\.sites/;
    my $chr=$1;
    my $window=$2;
    print "perl 04.06.flt.tro.Miss.bywindow.pl 04.05.HDflt.pl.out/OreOmu.$chr.HDflt.SNP.vcf.gz 04.05.HDflt.pl.out/OreOmu.$chr.HDflt.INDEL.vcf.gz $out/OreOmu.$chr.$window.HD.miss.snp.vcf.gz $chr $in\n";
}
