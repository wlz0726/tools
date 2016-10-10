#!/usr/bin/perl
my $f=shift;
open(IN, "$f");
open(OUT, "> $f.filterRefN.vcf");
while(<IN>){
    chomp;
    if (/^#/){
        print OUT "$_\n";
        next;
    }
    my @a=split (/\s+/);
        
    next if (length($a[3])>1 || length($a[4]>1));
    next if ($a[7] =~ /^INDEL/);
    $a[7] =~ /;AF1=([\.\d]+);/;
    next if($1==1);
    
    print OUT "$_\n";
}
close IN;
close OUT;
