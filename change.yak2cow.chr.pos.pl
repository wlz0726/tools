#!/usr/bin/perl

# pos 0 start  => pos 1 start;
my %h;
my $i=1;
open(IN,"/home/share/user/user104/projects/yak/chr.relationship.with.cattle/synteny.info");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $h{$a[4]}{$i}{direction}=$a[7];
    $h{$a[4]}{$i}{start}=$a[5]+1;
    $h{$a[4]}{$i}{end}=$a[6]+1;
    $h{$a[4]}{$i}{bta_chr}=$a[0];
    $h{$a[4]}{$i}{bta_start}=$a[1]+1;
    $h{$a[4]}{$i}{bta_end}=$a[2]+1;
    $i++;
}
close IN;

my $file=shift;
die "$0 1.pos\n"unless $file;
open(IN2,"$file");
open(OUT,"> $file.yak2cowChr");
#print OUT "#bta_chr\tbta_pos\tchr\tpos\tA1\tA2\tTEST\tAFF\tUNAFF\tP\n";
while(<IN2>){
    next if(/#/);
    chomp;
    my @a=split(/\s+/);
    if(exists $h{$a[0]}){
        foreach my $k1(sort keys %{$h{$a[0]}}){
            if(($h{$a[0]}{$k1}{start} <= $a[1]) && ($a[1] <= $h{$a[0]}{$k1}{end})){
	my $pos;
	if($h{$a[0]}{$k1}{direction} =~ /\+/){
	    $pos=$h{$a[0]}{$k1}{bta_start} + ($a[1] - $h{$a[0]}{$k1}{start});
	}elsif($h{$a[0]}{$k1}{direction} =~ /\-/){
	    $pos=$h{$a[0]}{$k1}{bta_end} - ($a[1] - $h{$a[0]}{$k1}{start});
	}
	print OUT "$h{$a[0]}{$k1}{bta_chr}\t$pos\t$_\n";
            }
        }
    }
}
close IN2;
close OUT;
