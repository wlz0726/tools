my $prefix=shift;
my $ped="$prefix.2.ped";
my $map="$prefix.2.map";

my $head=$prefix;
my $dir2="pca.$head";
mkdir $dir2;
open(O,'>',"$head.02.pca.sh");

print O "/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/plink/plink1.9/plink --tfile $prefix --out $prefix.2 --recode;\n";
#print O "perl 5.ChangeMap.pl $map\n";
print O "perl 6.MakeInd.pl $ped\n";
print O "/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/EIGENSOFT/EIG5.0.1/bin/smartpca.perl -i $ped -a $map -b $ped","ind -o $dir2/2.$head.PCA -p $dir2/2.$head.PCA.plot -e $dir2/2.$head.PCA.eigenvalues -l $dir2/2.$head.PCA.log\n";
print O "perl 7.ggplot.pl $dir2/2.$head.PCA.evec\n";

close(O);
