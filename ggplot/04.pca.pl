my $in=shift;

die "
input format:
B1 -16.603414  10.068600  -2.3032266  22.320859     B
B2  32.742374  25.482192  -0.4221798   1.523013     B
B3 -55.279881 -15.200939 -16.5020267  21.147049     B
B4 -11.440939  11.533090  13.4287069  23.833101     B
B5  40.903783  16.998958  24.1000004  16.350140     B
B6  41.827626 -24.487984 -40.6895348  11.205686     B
C1  22.172632 -51.597140  33.3374270  -8.334499     C
C2  16.634217  24.325850 -11.2100076 -32.083611     C
C3 -48.346499   2.166823  12.4517301 -23.379801     C
C4 -20.166464  11.323183   2.6713706  -7.530603     C
C5  -2.443435 -10.612632 -14.8622596 -25.051334     C

"unless $in;

open(O,"> $f.r");
print O "
library(ggplot2)
data=read.table(\"$in\",header=F)

# pc1 2
pdf(file=\"$in.PC12.pdf\")
ggplot(data,aes(V2,V3,color=factor(V6)))+geom_point()+xlab(\"PC1\")+ylab(\"PC2\")+theme(legend.title=element_blank())
dev.off()

# pc1 3
pdf(file=\"$in.PC13.pdf\")
ggplot(data,aes(V2,V4,color=factor(V6)))+geom_point()+xlab(\"PC1\")+ylab(\"PC3\")+theme(legend.title=element_blank())
dev.off()

# pc2 3
pdf(file=\"$in.PC23.pdf\")
ggplot(data,aes(V3,V4,color=factor(V6)))+geom_point()+xlab(\"PC2\")+ylab(\"PC3\")+theme(legend.title=element_blank())
dev.off()


# pc1 4
pdf(file=\"$in.PC14.pdf\")
ggplot(data,aes(V2,V5,color=factor(V6)))+geom_point()+xlab(\"PC1\")+ylab(\"PC4\")+theme(legend.title=element_blank())
dev.off()

# pc2 4
pdf(file=\"$in.PC24.pdf\")
ggplot(data,aes(V3,V5,color=factor(V6)))+geom_point()+xlab(\"PC2\")+ylab(\"PC4\")+theme(legend.title=element_blank())
dev.off()

# pc3 4
pdf(file=\"$in.PC34.pdf\")
ggplot(data,aes(V4,V5,color=factor(V6)))+geom_point()+xlab(\"PC3\")+ylab(\"PC4\")+theme(legend.title=element_blank())
dev.off()
";

close O;

`/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/R-3.1.1/bin/Rscript $f.r`;
`rm $f.r`;
