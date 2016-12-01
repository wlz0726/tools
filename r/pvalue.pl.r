
b=read.table("02.CNVnatorFilter.pl.1000.out.annot.B",header=F)
c=read.table("02.CNVnatorFilter.pl.1000.out.annot.C",header=F)
cnv_number_b=b$V2
cnv_number_c=c$V2
Genetic_CNV_number_b=b$V6
Genetic_CNV_number_c=c$V6
CNV_gene_number_b=b$V7
CNV_gene_number_c=c$V7

p_cnv_number=wilcox.test(cnv_number_b,cnv_number_c)
p_Genetic_CNV_number=wilcox.test(Genetic_CNV_number_b,Genetic_CNV_number_c)
p_CNV_gene_number=wilcox.test(CNV_gene_number_b,CNV_gene_number_c)
head=paste("cnv_number	Genetic_CNV_number	CNV_gene_number")
line=paste(p_cnv_number$p.value,p_Genetic_CNV_number$p.value,p_CNV_gene_number$p.value)
write.table(head,file="pvalue.pl.out",append = TRUE,row.names=FALSE,col.names=FALSE,quote = FALSE);
write.table(line,file="pvalue.pl.out",append = TRUE,row.names=FALSE,col.names=FALSE,quote = FALSE);
