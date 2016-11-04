#!/usr/bin/perl -w
my %go;
open (IN, "< Gene2GoID.cattle.table");
open (OUT, "> Gene2GoID.cattle.table.go2gene");
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    for(my $i=1;$i<@a;$i++){
        $go{$a[$i]}{$a[0]}++
    }
}
close IN;

foreach my $a(sort keys %go){
    print OUT "$a\t",join("\t",keys %{$go{$a}}),"\n";
}
close OUT;

