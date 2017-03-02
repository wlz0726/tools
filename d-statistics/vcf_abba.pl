#! /usr/bin/env perl
# Uses: This script is used to calculate ABBA from a vcf file.
# Input: vcf file, the sample names to calculate, Window size
# Output: ABBA value, z-value
# Author: Kun Wang
# Date: 2015/08/01

use strict;
use warnings;
use List::Util;

my ($vcf,$sample_list,$window_size,$output_prefix)=@ARGV;
die "Usage: $0 <vcf/vcf.gz> <sample list> [window size] [output prefix]\nsample list format: H1 H2 H3 O\ndefault windows size is 5000000\n" if(@ARGV < 2);
if(!$window_size){
    $window_size=5000000;
}
if(!$output_prefix){
    $output_prefix=$sample_list.".abba";
}
my $output_window="$output_prefix".".windows";
my $output_sta="$output_prefix".".sta";

sub sum {
    my (@values) = @_;
    my $total = 0;
    $total += $_ for @values;

    return $total;
}

sub average {
    my (@values) = @_;

    my $count = scalar @values;
    my $total = 0; 
    $total += $_ for @values; 

    return $count ? $total / $count : 0;
}

sub std_dev {
    my ($average, @values) = @_;

    my $count = scalar @values;
    my $std_dev_sum = 0;
    $std_dev_sum += ($_ - $average) ** 2 for @values;

    return $count ? sqrt($std_dev_sum / $count) : 0;
}

my %sample;
open(I,"< $sample_list");
my $combinationNo = 0;
while (<I>) {
    next if(/^#/);
    $combinationNo++;
    chomp;
    my @a = split(/\s+/);
    die "Four species should be specified!\n" if(@a != 4);
    $sample{$combinationNo} = [@a];
}
close I;

my %abbaData;

if($vcf=~/\.gz$/){
    open(I,"zcat $vcf |");
}
else {
    open(I,"< $vcf");
}

my @head;
while (<I>) {
    chomp;
    next if(/^##/);
    if(/^#/){
        @head = split(/\s+/);
        my %sampleId;
        for(my $i = 9;$i < @head;$i++){
            my $id = $head[$i];
            $sampleId{$id} = 1;
        }
        foreach my $combinationNo(sort {$a<=>$b} keys %sample){
            my $light = 1;
            my @sample = @{$sample{$combinationNo}};
            foreach my $id(@sample){
	if(!exists $sampleId{$id}){
	    $light = 0;
	    print STDERR "$id in line $combinationNo cannot be found in the vcf file!\n";
	}
            }
            if($light == 0){
	delete $sample{$combinationNo};
            }
        }
        if((keys %sample) == 0){
            die "\nERROR: we cannot find some samples in the given vcf file!\n";
        }
        last;
    }
}
if(@head == 0){
    die "vcf file must be specified!\n";
}
my $line_number = 0;
while (<I>) {
    $line_number++;
    if($line_number % 100000 == 0){
        print STDERR " [ $line_number ] lines loaded...\r";
    }
    chomp;
    my @a = split(/\s+/);
    my %siteInfo;
    for(my $i = 9;$i < @a;$i++){
        my $id = $head[$i];
        $siteInfo{$id} = ".";
        next unless($a[$i]=~/([\d])[\|\/]([\d])/);
        my ($left,$right) = ($1,$2);
        $siteInfo{$id} = $left+$right;
    }
    foreach my $combinationNo(sort {$a<=>$b} keys %sample){
        my $light = 1; # 如果light=0，则跳过此行
        my $abbaType;

        my @sample = @{$sample{$combinationNo}};
        foreach my $id(@sample){
            my $info = $siteInfo{$id};
            if($info eq "1" || $info eq "."){ # 如果有样品没有信息或者是杂合位点，则light为0
	$light = 0;
            }
            $abbaType .= $info;
        }

        next if($light == 0);
        my $chr = $a[0];
        my $pos = int($a[1]/$window_size)*$window_size;
        if(!exists $abbaData{$combinationNo}{$chr}{$pos}){
            $abbaData{$combinationNo}{$chr}{$pos}{abba} = 0;
            $abbaData{$combinationNo}{$chr}{$pos}{baba} = 0;
            $abbaData{$combinationNo}{$chr}{$pos}{bbaa} = 0;
        }
        if($abbaType=~/2$/){
            $abbaType=~tr/02/20/;
        }
        if($abbaType eq "0220"){
            $abbaData{$combinationNo}{$chr}{$pos}{abba}++;
        }
        elsif($abbaType eq "2020"){
            $abbaData{$combinationNo}{$chr}{$pos}{baba}++;
        }
        elsif ($abbaType eq "2200") {
            $abbaData{$combinationNo}{$chr}{$pos}{bbaa}++;
        }
    }
}
close I;
print STDERR "\nvcf file loaded.\n";

open(W,"> $output_window");
print W "chr\tpos\tabba\tbaba\tbbaa\tD\n";

open(S,"> $output_sta");
print S "H1\tH2\tH3\tO\tabba\tbaba\tbbaa\tD\tjackknife ( se:Z )\tbootstrap( se:Z )\n";

foreach my $combinationNo(sort {$a<=>$b} keys %abbaData){
    my @sample = @{$sample{$combinationNo}};
    my $abba_genome;
    my $baba_genome;
    my $bbaa_genome;
    my @d_value;
    my @abba_baba_window;
    print W "# ",join "\t",@sample,"\n";
    my $i=0; # $i变量表示基因组上的第几个window
    foreach my $chr(sort keys %{$abbaData{$combinationNo}}){
        my @pos = sort {$a<=>$b} keys %{$abbaData{$combinationNo}{$chr}};
        pop @pos;
        foreach my $pos(@pos){
            my $abba = $abbaData{$combinationNo}{$chr}{$pos}{abba};
            my $baba = $abbaData{$combinationNo}{$chr}{$pos}{baba};
            my $bbaa = $abbaData{$combinationNo}{$chr}{$pos}{bbaa};
            # next if($abba < 10 || $baba < 10 || $bbaa < 10);
            next if($abba+$baba == 0);
            # next if($bbaa < 10);
            $abba_baba_window[$i][0]=$abba;
            $abba_baba_window[$i][1]=$baba;
            $i++;
            my $d_window = ($abba-$baba)/($abba+$baba);
            my @window_line = ($chr,$pos,$abba,$baba,$bbaa,$d_window);
            print W join "\t",@window_line,"\n";
            push @d_value,$d_window;
            $abba_genome += $abba;
            $baba_genome += $baba;
            $bbaa_genome += $bbaa;
        }
    }
    print W "\n";
    next if(@d_value == 0);
    my $d_genome = ($abba_genome-$baba_genome)/($abba_genome+$baba_genome);

    my ($jack_se,$jack_z)=&jackknife($d_genome,@abba_baba_window);
    my ($boot_se,$boot_z)=&bootstrap($d_genome,@abba_baba_window);

    my @sta_line = (@sample,$abba_genome,$baba_genome,$bbaa_genome,$d_genome,$jack_se,$jack_z,$boot_se,$boot_z);
    print S join "\t",@sta_line,"\n";
}

close W;
close S;

sub jackknife{
    my $d_genome=shift;
    my @a=@_;

    my $nblock = scalar(@a);

    my @d_value;
    my $d_correction = 0;
    for(my $i=0;$i<@a;$i++){
        my @new_array = @a;
        splice(@new_array,$i,1);
        my $d = &d_stat(@new_array);
        push @d_value,$d;
    }

    my $se = &std_dev(@d_value);
    my $z  = $se? $d_genome/$se : 0;
    return ($se,$z);
}

sub bootstrap{
    my $d_genome=shift;
    my @a=@_;
    my $nblock = scalar(@a);
    my $nblock_half = int($nblock/2);

    my @d_value;
    for(my $i=0;$i<1000;$i++){
        my @new_array = List::Util::shuffle @a;
        splice(@new_array,0,$nblock_half);
        my $d = &d_stat(@new_array);
        push @d_value,$d;
    }

    my $se = &std_dev(@d_value);
    my $z  = $se? $d_genome/$se : 0;
    return ($se,$z);
}

sub d_stat{
    my @a = @_;
    my $abba = 0;
    my $baba = 0;
    for(my $i=0;$i<@a;$i++){
        $abba += $a[$i][0];
        $baba += $a[$i][1];
    }
    return ($abba+$abba)? ($abba-$baba)/($abba+$abba) : 0;
}
