my %root;
open(IN,"02.GOfromLeafToAllRoot.list");
while(<IN>){
    chomp;
    my @a=split(/\t/);
    $root{$a[0]}=$a[3];
}
close IN;



my %h;
open(IN,"01.print.Gene2GO.pl.txt");
open(OUT,"> $0.out");
while(<IN>){
    chomp;
    my @a=split(/\t/);
    my @out;
    for(my $i=1;$i<@a;$i++){
        my $leaf=$a[$i];
        if(exists $root{$leaf}){
            push(@out,$root{$leaf});
        }
    }
    my $go=join("\t",@out);
    $go =~s/;/\t/g;
    
    print OUT "$a[0]\t$go\n";
}
close IN;
close OUT;
