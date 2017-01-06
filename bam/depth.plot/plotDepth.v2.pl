my $in=shift;
$in =~ /\/.*\/([^\/]*)\-(.*)\-(.*).depth.gz/;
my $scaffold=$1;
my $start=$2;
my $end=$3;

open(O,"> $in.2.r");
print O "
library(ggplot2)
library(grid)
library(gridExtra)
library(RColorBrewer)

a=read.table(\"$in.ALL\",head=F)
mycolor =brewer.pal(n=8, 'Paired')

pdf(file=\"$in.V2.pdf\",width=10,height=20)
";
for(my $i=3;$i<=8;$i++){
    my $j=$i-2;
    print O "

p$i=ggplot(a,aes(V2/1000,V$i))+geom_point(size=0.5,color=mycolor[2])+ theme_bw()+theme(  legend.title = element_blank(),  panel.grid.minor=element_blank(),axis.text.x=element_blank())+labs(x=\" \",y=\"B$j\")+geom_vline(xintercept=$start/1000,color=\"black\", linetype=2)+geom_vline(xintercept=$end/1000,color=\"black\", linetype=2)+ geom_hline(yintercept=1,color=\"black\", linetype=2)+ylim(0,5)
";
}

for(my $i=9;$i<=13;$i++){
    my $j=$i-8;
    print O "

p$i=ggplot(a,aes(V2/1000,V$i))+geom_point(size=0.5,color=mycolor[6])+ theme_bw()+theme(  legend.title = element_blank(),  panel.grid.minor=element_blank(),axis.text.x=element_blank())+labs(x=\" \",y=\"C$j\")+geom_vline(xintercept=$start/1000,color=\"black\", linetype=2)+geom_vline(xintercept=$end/1000,color=\"black\", linetype=2)+ geom_hline(yintercept=1,color=\"black\", linetype=2)+ylim(0,5)                                                                                                                          ";
}


#print O "p13=ggplot(a,aes(V2/1000,V13))+geom_point(size=0.5,color=mycolor[6])+ theme_bw()+theme(  legend.title = element_blank(),  panel.grid.minor=element_blank())+labs(x=\"$scaffold     Positions (kb)\",y=\"\")+geom_vline(xintercept=$start/1000,color=\"black\", linetype=2)+geom_vline(xintercept=$end/1000,color=\"black\", linetype=2)+ geom_hline(yintercept=1,color=\"black\", linetype=2)+ylim(0,5)";


print O "
grid.arrange(p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,nrow=11)
dev.off()
";
close O;


`/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/R-3.1.1/bin/Rscript $in.2.r`;
#`rm $in.2.r`;
