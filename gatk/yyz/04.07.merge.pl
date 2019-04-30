use strict;
use warnings;

my @in=<04.06.flt.tro.Miss.bywindow.run.pl.out/*HD.miss.snp.vcf.gz>;
my %list;
for my $in (@in){
    $in=~/\/OreOmu.(\w+)\.(\d+)-(\d+)/;
    $list{$1}{$2}=$in;
}
print "zcat 00.vcf.header.gz ";
for my $k (sort keys %list){
    for my $k2 (sort{$a<=>$b} keys %{$list{$k}}){
        print "$list{$k}{$k2} ";
    }
}
print " | gzip -c > $0.OreOmu.HDflt.miss.SNP.vcf.gz\n";
