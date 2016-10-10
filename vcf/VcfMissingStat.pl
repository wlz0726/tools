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
        
        #if(($a[$i] =~ /^0\/0/) || ($a[$i] =~ /^1\/1/)){
        #    $h{$id}{homo}++;
        #}elsif($a[$i] =~ /0\/1/){
        #    $h{$id}{heter}++;
        #}
    }
    
    
}
close IN;

foreach my $a (keys %h){
    #print OUT "$a\t$h{$a}{miss}\t$h{$a}{homo}\t$h{$a}{heter}\n";
    print OUT "$a\t$h{$a}{miss}\n";
}
print OUT "total:\t$total\n";
close OUT;
