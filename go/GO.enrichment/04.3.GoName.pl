my $in="result.04.txt.fdr";

my %h;
open(IN,"04.GoEnrichment.pl.GoName");
while(<IN>){
    chomp;
    my @a=split(/\t/);
    $h{$a[0]}="$a[1]\t$a[2]";
}
close IN;


open(IN,"$in");
open(OUT,"> $in.name");
open(OUT2,"> $in.name.0.05");
print OUT "GO\tP\tlist1InGO\tlist1OutGO\tlist2InGO\tlist2OutGO\tfdr\ttype\tfunction\n";
print OUT2 "GO\tP\tlist1InGO\tlist1OutGO\tlist2InGO\tlist2OutGO\tfdr\ttype\tfunction\n";
while(<IN>){
    chomp;
    next if(/list1InGO/);
    my @a=split(/\s+/);
    $a[1] =~ s/\"//g;
    my $print;
    if(exists $h{$a[1]}){
        $print =$h{$a[1]};
    }else{
        $print ="-\t-";
    }
    print OUT "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t$print\n";
    if($a[7]<=0.05){
        print OUT2 "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t$print\n";
    }
}
close IN;
close OUT;
close OUT2;
