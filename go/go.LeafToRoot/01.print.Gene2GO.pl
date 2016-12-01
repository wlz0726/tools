my %h;
open(IN,"mart_export.txt");
<IN>;
while(<IN>){
    chomp;
    my @a=split(/\t/);
    next if(@a<4);
    #print "$a[2]\n";
    $h{$a[0]}{$a[2]}++;
}
close IN;

open(OUT,"> 01.print.Gene2GO.pl.txt");
foreach my $gene(keys %h){
    my @out;
    foreach my $n(sort keys %{$h{$gene}}){
        #push(@out,$h{$gene}{$n});
        push(@out,$n);
    }
    print OUT "$gene\t",join("\t",@out),"\n";
}
close OUT;
