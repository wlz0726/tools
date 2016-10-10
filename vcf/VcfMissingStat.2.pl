#!/usr/bin/perl -w
my $file=shift;
my @id;
open(IN, "$file");
open(OUT, "> $file.missing.out");

my $total=0;
while(<IN>){
    chomp;
    next if (/^##/);
    if(/^#/){
        @id=split(/\t/,$_);
        next;
    }
    $total++;
    my @a=split (/\s+/);
    for(my $i=9;$i<@a;$i++){
        my $id=$id[$i];
        
        if($a[$i] =~ /^\.\/\./){
            $h{$id}{miss}++;
            next;
        }
        
        my @b=split (/:/,$a[$i]);
        if($b[2] < 2){
            $h{$id}{miss}++;
            next;
        }
    }
}
close IN;

print OUT "total:\t$total\n\n";

foreach my $a (keys %h){
    my $per=$h{$a}{miss}/$total;
    print OUT "$a\t$h{$a}{miss}\t$per\n";
}
close OUT;
