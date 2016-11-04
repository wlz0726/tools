my $list=shift;

open(IN,"$list");
open(OUT,"> $list.txt");
print OUT "probeID GOIDs\n";
while(<IN>){
    chomp;
    my @b;
    my @a=split(/\s+/);
    for(my $i=1;$i<@a;$i++){
        push(@b,$a[$i]);
    }
    print OUT "$a[0]\t",join(" \/\/ ",@b),"\n";
}
close IN;
