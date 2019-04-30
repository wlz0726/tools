#! /usr/bin/perl
use strict;
use warnings;

my $list=shift;

die "perl $0 gwas.txt

file format:
CHR SNP BP P
1 rs4475691 846808 0.1588
1 rs7537756 854250 0.1584
1 rs13303010 894573 0.8704
1 rs2341365 948692 0.8045

    \n" unless $list;
my $name=$list;
$name =~ s/.txt$//;

open(OUT,"> $list.Rscript");

print OUT "
library(qqman)
gwasResults=read.table(\"$list\",header=T)
options(bitmapType='cairo')
# 780 * 480
#png(\"$list.png\",width=1200,height=600,res=150,pointsize=3,units = \"px\")
png(\"$list.png\",width=780,height=480,units = \"px\")
#manhattan(gwasResults,main=\"$name\",col=c(\"grey10\",\"grey50\"))
 manhattan(gwasResults,main=\"$name\",col=c(\"#bebebe\",\"#4fb1f7\"))
dev.off()

png(\"$list.qqplot.png\")
qq(gwasResults\$P,main =\"$name\")
# genomic inflation factor lambda
#lambda <- qchisq(median(gwasResults\$P,na.rm=T),1,lower.tail=FALSE)/qchisq(0.50,1,lower.tail=FALSE)
lambda <- median(qchisq(1-gwasResults\$P,1),na.rm=T)/qchisq(0.5,1)
# qchisq(median(gwasResults\$P,na.rm=T),1,lower.tail=FALSE)/qchisq(0.50,1,lower.tail=FALSE)
legend('topleft',legend=bquote(\"Median\"~lambda == .(round(lambda,3))),bg='white',bty='n',cex=1)
dev.off()


#gwasResults\$fdr=p.adjust(gwasResults\$P,method=\"fdr\")
#gwasResults\$bonferroni=p.adjust(gwasResults\$P,method=\"bonferroni\")

#gwasResults\$Z=(gwasResults\$P - mean(gwasResults\$P))/sd(gwasResults\$P)
#write.table(gwasResults,file=\"$list.adusted\",quote = F, row.names = F,sep=\"\t\")
    

";


close OUT;
`Rscript $list.Rscript`;
#`rm $list.Rscript`;
