my $prefix=shift;
my $ped="$prefix.ped";
my $map="$prefix.map";

my $head;
if($ped=~m/(.*)\.ped/){
    $head=$1;
}
my $dir2="pca.$head";
mkdir $dir2;
open(O,'>',"$head.02.pca.sh");
#print O "perl $dir/5.ChangeMap.pl $map\n";
print O "perl 6.MakeInd.pl $ped\n";
print O "/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/EIGENSOFT/EIG5.0.1/bin/smartpca.perl -i $ped -a $map.map -b $ped","ind -o $dir2/2.$head.PCA -p $dir2/2.$head.PCA.plot -e $dir2/2.$head.PCA.eigenvalues -l $dir2/2.$head.PCA.log\n";
print O "perl 7.ggplot.pl $dir2/2.$head.PCA.evec\n";

close(O);
