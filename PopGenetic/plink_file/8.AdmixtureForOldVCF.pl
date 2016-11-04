my $prefix=shift;
my $k=5;
$prefix =~ /(.*)/;
my $dir=admix.$1;
mkdir "$dir";
open(O,'>',"$1.03.admix.sh");
open(O2,'>',"$dir/$1.04.admix.sh");
open(O3,"> $1.05.admix.sh");
print O "plink --noweb --ped $prefix.ped --map $prefix.map.map --indep-pairwise 50 10 0.2 --out $dir/1.$1.pruned;\n";
print O "plink --noweb --ped $prefix.ped --map $prefix.map.map --extract $dir/1.$1.pruned.prune.in --recode12 --out $dir/1.$1.extract\n";

for(my $i=1;$i<=$k;$i++){
    print O2 "admixture --cv -j30 1.$1.extract.ped $i > 1.$1.extract.log$i.out\n";
}
print O3 "perl 9.PlotAdmixture.pl $dir\n";
close(O);
close(O2);
close O3;
