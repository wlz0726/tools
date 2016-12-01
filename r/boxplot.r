bb1=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.B_B_1pb",header=F)
bc1=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.B_C_1pb",header=F)
cc1=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.C_C_1pb",header=F)

bb5=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.B_B_50per",header=F)
bc5=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.B_C_50per",header=F)
cc5=read.table("03.Overlap.pl.NumberOfOverlapBetweenPops.C_C_50per",header=F)

pdf(file="06.plot.NumberOfOverlapBetweenPops.pdf")   
par(mfrow=c(1,2))
boxplot(bb1$V2,bc1$V2,cc1$V2,outline = F,names=c("B-B","B-C","C-C"),main="1 bp overlap")
boxplot(bb5$V2,bc5$V2,cc5$V2,outline = F,names=c("B-B","B-C","C-C"),main="50% reciprocal overlap")
dev.off()
