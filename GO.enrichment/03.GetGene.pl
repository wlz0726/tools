use strict;
use warnings;

my $gff="fixed.gff";
my $list="in.txt";

my %gff;

my %annot;
open(IN,"Gene2GoID.cattle.table");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $annot{$a[0]}++;
}
close IN;

open(I,"< $gff");
while (<I>) {
    next unless(/mRNA.*ID=([\w-]+);/);
    my $id=$1;
    my @a=split(/\s+/);
    $gff{$a[0]}{$id}{start}=$a[3];
    $gff{$a[0]}{$id}{end}=$a[4];
}
close I;

open(I,"< $list");
open(S,"> $list.03.out");

my %select;
while (<I>) {
    chomp;
    next if(/^#/);
    my @a=split(/\s+/);
    my $start=$a[1];
    my $end=$a[2];
    foreach my $id(keys %{$gff{$a[0]}}){
        
        #### Gene in window
        #####next unless($gff{$a[0]}{$id}{start} < $end && $gff{$a[0]}{$id}{end} > $start);
        #### Gene Overlap with Window
        next if($gff{$a[0]}{$id}{end} < $start);
        next if($gff{$a[0]}{$id}{start} > $end);
        # gene have GO annotation
        next if(!$annot{$id});
        $select{$id}++;
    }
}
close I;

foreach my $id(sort keys %select){
    print S "$id\n";
}
close S;

