#!/usr/bin/perl -w
my ($file,$list)=@ARGV;
die("$0: VcfFile LengthLimitList\n") unless($list);

my %h;
my $line;
open(IN, "$list");
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    $h{$a[0]}++;
    $line++;
}
close IN;
#`wc -l $list`;
print "$line\n";
$list =~ /Length\.(\d+)\.Limit\.list/;
my $length=$1;
my %h2;
open(IN, "$file");
open(OUT, "> $file.LengthBiggerThan.$length.vcf");
while(<IN>){
    chomp;
    if (/^##/){
        print OUT "$_\n";
        next;
    }
    if(/^#/){
        print OUT "$_\n";
        next;
    }
    my @a=split (/\s+/);
    if(exists $h{$a[0]}){
        print OUT "$_\n";
        $h2{$a[0]}++;
    }
}
my $num=keys %h2;
print "$num\n";
close IN;
close OUT;
