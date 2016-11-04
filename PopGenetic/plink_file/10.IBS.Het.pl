my $prefix=shift;
#die "$0 pedprefix\n" unless $prefix;
open(O,"> $prefix.00.IBS.Het.sh");
print O "
plink --noweb --file $prefix --genome --out $prefix.D.IBD --min 0 --max 1 --keep 0.D66.keep.list
plink --noweb --file $prefix --genome --out $prefix.W.IBD --min 0 --max 1 --keep 0.W14.keep.list

plink --noweb --file $prefix --het --out $prefix.het.D --keep 0.D66.keep.list
plink --noweb --file $prefix --het --out $prefix.het.W --keep 0.W14.keep.list 

#plink --file $prefix --het --homozyg  --out $prefix.homezyg


";
close O;
