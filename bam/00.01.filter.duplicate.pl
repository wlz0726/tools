
#!/usr/bin/perl
use strict;
use warnings;

my %h;
my $file=shift;
#print "first\n";
open (F,"samtools view $file | ");
while (<F>) {
    chomp;
    next if(/^\s*$/);
    next  if (/^@/);
    my @a=split(/\s+/,$_);
    $h{$a[0]}++;
}
close F;
#print "second\n";
open (IN,"samtools view -h $file | ");
open (O," | samtools view -bS -o $file.filter.bam -");
while (<IN>) {
    chomp;
    next if(/^\s*$/);
    if (/^@/){
        print O "$_\n";
        next;
    }
    my @a=split(/\s+/,$_);
    next if ($h{$a[0]} > 2);
    print O "$_\n";
}
close IN;
close O;
