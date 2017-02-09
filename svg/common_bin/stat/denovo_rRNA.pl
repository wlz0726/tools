#!/usr/bin/perl -w
use strict;
##
##stat rRNA result by method of de novo
##
my (%s5, %s16, %s23);
my ($count_5s, $count_16s, $count_23s);
my ($length_5s, $length_16s, $length_23s);
die "perl $0 rRNA.gff sequence.fa \n" if (@ARGV != 2);
my ($rRNA, $sequence) = @ARGV;
my $rRNA_num = 0;

open RNA,$rRNA or die 'cannot open the file, ', "$!\n";
while(<RNA>)
{
	next if(/^#/);
	my ($seqname, $source, $feature, $start, $end, $score, $strand, $frame, $attribute) = split;
	if($attribute eq '5s_rRNA')
	{
		++$count_5s;
		$length_5s += ($end-$start+1);

	}
	elsif($attribute eq '16s_rRNA')
	{
		++$count_16s;
		$length_16s += ($end-$start+1);
	}
	elsif($attribute eq '23s_rRNA')
	{
		++$count_23s;
		$length_23s += ($end-$start+1);
	}
	else
	{
		warn("unknown attribute!\n");
	}	
}
close RNA;

my $total_length = &readfasta($sequence);
$length_5s ||= 0;
$length_16s ||= 0;
$length_23s ||= 0;
my $total_ratio = sprintf("%.4f", 100*($length_5s+$length_16s+$length_23s)/$total_length);
#print "Type\tCopy#\tAvg_Len\tTotal_Len\t% in Genome\n";
#print "rRNA_de";
if (defined $count_5s)
{
	my $temp_avg = $length_5s/$count_5s;
	&comma_add (0, $count_5s, $temp_avg, $length_5s);
	print "rRNA_de\t", "5s\t$count_5s","\t", $temp_avg, "\t", $length_5s, "\n";
	$rRNA_num += $count_5s;
}
else
{
	print "rRNA_de\t", "5s\t0","\t", 0,"\t",0, "\n";
}
if (defined $count_16s)
{
	my $temp_avg = $length_16s/$count_16s;
	&comma_add (0, $count_16s, $temp_avg, $length_16s);
	&comma_add (4, $total_ratio);
	print "\t", "16s\t$count_16s","\t", $temp_avg,"\t",$length_16s, "\t", $total_ratio, "\n";
	$rRNA_num += $count_16s;
}
else
{
	&comma_add (4, $total_ratio);
	print "\t", "16s\t0","\t", 0,"\t",0, "\t", $total_ratio, "\n"
}
if (defined $count_23s)
{
	my $temp_avg = $length_23s/$count_23s;
	&comma_add (0, $count_23s, $temp_avg, $length_23s);
	print "\t", "23s\t$count_23s","\t", $temp_avg,"\t",$length_23s, "\t", "\n";
	$rRNA_num += $count_23s;
}
else
{
	print "\t", "23s\t0","\t", 0,"\t",0, "\t\t", "\n";
}

print "$rRNA_num\n";


##########################################subroutine
sub readfasta
{
	my $fa_file = shift or die 'no parameter input ', "\n";
	my $fa_length = 0;
	my $original = $/;
	open FASTA, $fa_file or die 'cannot open the file, ', $!, ". \n";
	$/ = '>';
	while(<FASTA>)
	{
		chomp;
		next unless $_;
		my ($id, $seq) = split(/\n/, $_, 2);
		$seq =~ s/[\n\s]//mg;
		$fa_length += length($seq);
	}
	$/ = $original;
	close FASTA;
	return $fa_length;
}

sub comma_add {
	my $nu = shift;
	my $arg = "%.${nu}f";
	foreach (@_) {
		$_ = sprintf($arg,$_);
		$_ = /(\d+)\.(\d+)/ ? comma($1) . '.' . $2 : comma($_);
	}
}
sub comma{
	my ($c,$rev) = @_;
	(length($c) > 3) || return($c);
	$rev || ($c = reverse $c);
	$c =~ s/(...)/$1,/g;
	$rev || ($c = reverse $c);
	$rev ? ($c =~ s/,$//) : ($c =~ s/^,//);
	$c;
}
