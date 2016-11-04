my $f=shift;
my $out="$f.ggplot2";
open(I,"< $f");
<I>;
my @head=("FID");

for(my $i=1;$i<=10;$i++){
    my $h=PC."$i";
    push @head,$h;
}
push @head,"species";
my $head=join "\t",@head;
open(O,"> $out");
print O "$head\n";
while(<I>){
    chomp;
    s/^\s+//;
    print O "$_\n";
}
close I;
close O;

open(R,"> $f.R");
print R "
library(\"ggplot2\");
a=read.table(\"$f.ggplot2\",header=T);
pdf(file=\"$f.PC1_PC2.pdf\");
ggplot(a,aes(PC1,PC2,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
pdf(file=\"$f.PC1_PC3.pdf\");
ggplot(a,aes(PC1,PC3,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
pdf(file=\"$f.PC1_PC4.pdf\");
ggplot(a,aes(PC1,PC4,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
pdf(file=\"$f.PC2_PC3.pdf\");
ggplot(a,aes(PC2,PC3,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
pdf(file=\"$f.PC2_PC4.pdf\");
ggplot(a,aes(PC2,PC4,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
pdf(file=\"$f.PC3_PC4.pdf\");
ggplot(a,aes(PC3,PC4,color=species))+geom_point(alpha=0.9,size=4)+theme_blank();
#+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))#+theme_blank();
dev.off;
";
close R;
`Rscript $f.R`;
