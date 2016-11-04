
my $prefix=shift;

$prefix =~ /(.*)/;
#my $1=$prefix;
my $dir="nj.$1";
mkdir $dir unless -e $dir;
open(O ,'>',"$1.01.njtree.sh");
#print  O "vcftools --vcf $vcf --plink --out $prefix\n";
print O "/opt/blc/genome/biosoft/plink-1.07/plink --ped $prefix.ped --map $prefix.map --cluster --distance-matrix --noweb --out $dir/2.$1\n";
print O "perl 2.mdist2phylip.pl $dir/2.$1.mdist $prefix.ped $dir/3.$1.phylip\n";
print O "perl 3.phylip.pl $dir/3.$1.phylip $dir/4.$1.outfile 4.$1.outtree\n";
print O "/opt/blc/genome/biosoft/phylip-3.69/bin/neighbor 0<$dir/3.$1.phylip.config\n";
print O "mv outfile $dir/4.$1.outfile\n";
print O "mv outtree $dir/4.$1.outtree\n";
close(O);

