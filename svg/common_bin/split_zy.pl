#!/usr/bin/perl -w
use strict;
if(@ARGV == 0){die"usage:[in fasta][in cut #][in prefix]\n";};

open IN,"$ARGV[0]"or die;
my $total = 0;
while(my $line = <IN>){
	if($line =~ /^>/){
		$total++;
		next;
	};
};
close IN;

my $each = 0;
if($ARGV[1] > $total){
	$ARGV[1] = $total;
};
$each = int ( $total / $ARGV[1] ) ;

my $file = 1;
my $con = 0;
my $flag = 0;

open IN,"$ARGV[0]"or die;
open OUT,">$ARGV[2]_$file.fa"or die;

while(my $line = <IN>){
	chomp $line;
	if($line =~ /^$/){next;};

	if($line =~ /^>/ and $flag == 0){
		if($con == $each){
			$con = 0;
			$file++;
			if($file == $ARGV[1]){
				$flag ++;
			};
			close OUT;
			open OUT,">$ARGV[2]_$file.fa"or die;
		};
		$con++;
	};

	print OUT "$line\n";
};
close IN;
close OUT;
