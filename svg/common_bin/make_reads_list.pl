#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);


if (@ARGV != 3) { &usage && exit;}

my ($stat, $list, $outfile) = @ARGV;

my %hash_sample_reads;

open STAT, $stat || die "can not open file: $stat!\n";
while (<STAT>) {
	chomp;
	next if (/^\s*#|^\s*$|^\s*Sample_Name\s+/);
	my @w = split;
	$w[2] =~ s/[^\d]//g;
	my $read1 = `grep $w[0] $list| grep "$w[1]_1"`; $read1 =~ $1 if ($read1 =~ /^\s*(\S+)/); chomp $read1;
	my $read2 = `grep $w[0] $list| grep "$w[1]_2"`; $read2 =~ $1 if ($read2 =~ /^\s*(\S+)/); chomp $read2;
	push (@{$hash_sample_reads{$w[0]}{$w[1]}}, ($w[2], $read1, $read2)) if (-e $read1 && -e $read2);
	#B212    SZAIPI018454-40 471     105     0.068   0.045   100.00
}
close STAT;

open OUT, ">$outfile" || die "can not create file: $outfile!\n";
foreach (sort {$a cmp $b}keys %hash_sample_reads) {
	my $name = $_;
	foreach my $lane (keys %{$hash_sample_reads{$name}}) {
		print OUT "$name\t$hash_sample_reads{$name}{$lane}->[0]\t$hash_sample_reads{$name}{$lane}->[1]\t$lane\n";
		print OUT "$name\t$hash_sample_reads{$name}{$lane}->[0]\t$hash_sample_reads{$name}{$lane}->[2]\t$lane\n";
	}
}
close OUT;


################## sub function #########################
sub usage {
	print STDERR "
	usage:
	perl make_reads_list.pl <clean_stat> <clean reads list> <out file>
	example:
	perl make_reads_list.pl List/clean_stat.xls List/clean.lst List/clean_reads_table.xls
	\n\n";
}



__END__
