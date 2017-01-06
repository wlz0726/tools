my $in=shift;
$in =~ /\/.*\/([^\/]*)\-(.*)\-(.*).depth.gz/;
my $scaffold=$1;
my $start=$2;
my $end=$3;
open(O,"> $in.3.r");
print O "
library(ggplot2)

library(grid)
library(gridExtra)
library(RColorBrewer)


b=read.table(\"$in.Btxt\",head=F)
c=read.table(\"$in.Ctxt\",head=F)
mycolorb=brewer.pal(9, \"Blues\")
mycolorc=brewer.pal(9, \"Reds\")

pdf(file=\"$in.V3.pdf\")

bp=ggplot(b,aes(V1/1000,V2,color=factor(V3)))+geom_point(size=0.5)+ theme_bw()+scale_color_manual(values=mycolorb[8:3])+theme(  legend.title = element_blank(),  panel.grid.minor=element_blank(),axis.text.x=element_blank())+labs(x=\" \",y=\"Depth\")+geom_vline(xintercept=$start/1000,color=\"black\", linetype=2)+geom_vline(xintercept=$end/1000,color=\"black\", linetype=2)+ geom_hline(yintercept=1,color=\"black\", linetype=2)+ylim(0,5)

cp=ggplot(c,aes(V1/1000,V2,color=factor(V3)))+geom_point(size=0.5)+ theme_bw()+scale_color_manual(values=mycolorc[8:3])+theme(  legend.title = element_blank(),  panel.grid.minor=element_blank())+labs(x=\"$scaffold     Positions (kb)\",y=\"Depth\")+geom_vline(xintercept=$start/1000,color=\"black\", linetype=2)+geom_vline(xintercept=$end/1000,color=\"black\", linetype=2)+ geom_hline(yintercept=1,color=\"black\", linetype=2)+ylim(0,5)


grid.arrange(bp,cp,nrow=2)
dev.off()

";
close O;

`/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/R-3.1.1/bin/Rscript $in.3.r`;
#`rm $in.3.r`;
