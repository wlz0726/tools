use warnings;
use strict;

my $window=500000;
my $scaffold=0;
my $dir="01.vcfByWindow";
`mkdir $dir` if (! -e $dir);
my %len;
open (F,"00.header.txt");
while (<F>) {
    chomp;
    if (/SN\:(\S+)\s+LN\:(\d+)/){
        $len{$1}=$2;
    }
}
close F;

## split window ###
my @k=sort{$len{$b} <=> $len{$a}} keys %len;
for my $k (@k){
    my $len=$len{$k};
    if ($len > $window){
        for (my $i=1;$i<=$len;$i=$i+$window){
            $scaffold++;
            my $outdir="$dir/$scaffold";
            `mkdir $outdir` if (! -e "$outdir");
            my $end=$i+$window-1;
            $end=$len if $end>$len;
            #open (O,">$outdir/interver.list");
            print  "$scaffold\t$k:$i-$end\n";
            #close O;
        }
    }else{
        $scaffold++;
        my $outdir="$dir/$scaffold";
        `mkdir $outdir` if (! -e "$outdir");
        my $end=$len;
        #open (O,">$outdir/interver.list");
        print  "$scaffold\t$k:1-$end\n";
        #close O;
    }
}
