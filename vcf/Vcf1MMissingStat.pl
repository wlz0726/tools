#!/usr/bin/perl -w

my $file=shift;
my @id;
open(IN, "$file");
open(OUT, "> $file.missing.1M.out");

my $total=0;
while(<IN>){
    chomp;
    next if (/^##/);
    if(/^#/){
        @id=split(/\t/,$_);
        next;
    }
    last if ($total >= 1000000);
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

foreach my $a (keys %h){
    #print OUT "$a\t$h{$a}{miss}\t$h{$a}{homo}\t$h{$a}{heter}\n";
    my $per=$h{$a}{miss}/$total;
    print OUT "$a\t$h{$a}{miss}\t$per\n";
}
print OUT "total:\t$total\n";
close OUT;
