my $prefix=shift;
#die "$0 pedprefix\n" unless $prefix;
open(O,"> $prefix.00.king-relationship.sh");

print O "
plink --noweb --file $prefix --make-bed --out $prefix.D.bin --keep 0.D66.keep.list
plink --noweb --file $prefix --make-bed --out $prefix.W.bin --keep 0.W14.keep.list
king -b $prefix.D.bin.bed --kinship --prefix $prefix.D.bin.bed;# mv king.kin0 $prefix.D.bin.bed.king.kin0
king -b $prefix.W.bin.bed --kinship --prefix $prefix.W.bin.bed;# mv king.kin0 $prefix.W.bin.bed.king.kin0

";
close O;
