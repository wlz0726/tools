
a=read.table("result.04.txt",header=T)
p=a$x2
fdr=p.adjust(p,method='fdr')
a$fdr=fdr
write.table(a,file="result.04.txt.fdr")
