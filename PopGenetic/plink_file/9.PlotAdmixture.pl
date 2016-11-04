my $dir=shift;
my @file=`ls $dir/*.Q`;

#mkdir "AdmixtureForRawVCFPlot";

open(R,'>',"$dir/0.runR.$dir.r");
print R "library(\"ggplot2\")\n";

foreach my $file(@file){
    chomp $file;
    my $ped;
    my $prefix;
    my $suffix;
    if($file=~m/\/([^\/]+)\.(\d+)\.Q/){
        $prefix="$1";
        $suffix=$2;
        $ped="$dir/$prefix.ped";
    }else{
        die "$file\n";
    }
    my @ind=&readPed($ped);
    my $out1="$prefix.$suffix.result";
    my $out2="$prefix.$suffix.result.ggplot";
    open(O1,'>',"$dir/$out1");
    open(O2,'>',"$dir/$out2");
    open(F,$file);
    print O2 "id\tpercent\tk\n";
    my $i=0;
    while(<F>){
        chomp;
        my @a=split(/\s+/);
        for(my $j=0;$j<@a;$j++){
            print O2 "$ind[$i]\t$a[$j]\tk$j\n";
        }
        my $line=join "\t",@a;
        print O1 $ind[$i],"\t","$line\n";
        $i++;
    }
    close(F);
    close(O2);
    close(O1);
    print R "
a=read.table(\"$out2\",header=T)
pdf(file=\"$prefix.$suffix.pdf\",width=20,height=7)
ggplot(a,aes(x=id,y=percent))+geom_bar(stat=\"identity\",aes(fill=k),width=1)#+theme(panel.background=element_blank(),axis.text.x=element_text(angle=270),axis.ticks = element_blank(),legend.position = \"none\",axis.title.x=element_blank(),axis.title.y=element_blank())
dev.off()
";
    print "$file complete\n";
}
close(R);


sub readPed{
    my $file=shift;
    chomp $file;
    my @r;
    open(F,$file) || die "$!\n";
    while(<F>){
	chomp;
    if(/^(\S+)/){
      push @r,$1;
    }
    }
    close(F);
    return @r;
}
`cd $dir`; 
`Rscript 0.runR.$dir.r`;
