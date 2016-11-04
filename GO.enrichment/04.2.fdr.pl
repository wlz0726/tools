my $in="result.04.txt";
open(OUT,"> $in.fdr.r");
print OUT "
a=read.table(\"$in\",header=T)
p=a\$x2
fdr=p.adjust(p,method='fdr')
a\$fdr=fdr
write.table(a,file=\"$in.fdr\")
";
close OUT;
`Rscript $in.fdr.r`;
