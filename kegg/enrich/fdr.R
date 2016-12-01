Args <- commandArgs(T)
verbose=T
inf  = Args[1];
outf = Args[2];

#library(qvalue)

d <- read.table(inf, head=F)

n_row <- dim(d)[1]
ps = numeric(n_row)

for (i in 1:n_row) {
	mat <- matrix(as.numeric(as.vector(d[i, c(5,6,7,8)])), nr=2, byrow=T)
	ret <- fisher.test(mat, alternative="greater")
	ps[i] <- ret$p.value
}
p.fdr <- p.adjust(ps, method="BH")

out <- cbind(d[,c(1,2)], ps, p.fdr, d[,c(5,9)])

names(out) <- c("Pathway_ID", "Pathway_term", "Pvalue","FDR","Number_significant_genes_in_pathway", "significant_genes_in_pathway");
out[,2] <- gsub("_", " ", out[,2])
out[,3] <- sprintf("%.3E", out[,3])
out[,4] <- sprintf("%.3E", out[,4])
write.table(out, file=outf, col.names=T, row.names=F, quote=F, sep="\t")

#qret <- qvalue(ps)
#qvalue <- qret$qvalue
#out<-cbind(d, qvalue)
