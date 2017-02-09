#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd qw(chdir);
use Data::Dumper;

my (@tables, $cutoff, $sequence, $help);
GetOptions(
	'rRNA:s'	=>\@tables,
	'threshold:f'	=>\$cutoff,
	'sequence:s'	=>\$sequence,
	'help'		=>\$help,
);

&usage() unless(undef $help or @tables);

my $cwd = $ENV{'PWD'};
chdir $cwd;
my ($count_5s, $count_16s, $count_23s);
my ($length_5s, $length_16s, $length_23s);
my %rRNA;
my $rRNA_num = 0;
$cutoff = 0.8 if(!defined($cutoff));

foreach my $file_path (@tables)
{
	open TABLE, $file_path or die 'cannot open the gff file', "$!\n";
	while(<TABLE>)
	{
		next if(/^#/);
		chomp;
##1:Query_id  2:Query_length  3:Query_start  4:Query_end   5:Subject_id  6:Subject_length  7:Subject_start  8:Subject_end 
##9:Identity  10:Positive  11:Gap  12:Align_length  13:Score  14:E_value  15:Query_annotation  16:Subject_annotation
		my ($query_id, $query_length, $query_start, $query_end, $subject_id, $subject_length, $subject_start, $subject_end, $identity, $positive, $gap, $align_length, $score, $e_value, $query_anno, $subject_anno) = split;
		my $rRNA_type = 'unknown_type';
		next if($identity < 0.01);
		my $threshold = $align_length / $query_length;
		next if ($threshold < $cutoff);
		$positive = ($subject_start > $subject_end)?'-':'+';
		($subject_start, $subject_end) = ($positive eq '+') ? ($subject_start, $subject_end) : ($subject_end, $subject_start);
		if($query_id =~ /\w+\|(\S+)\|\S+\|(\S+)$/)
		{
			$rRNA_type = $2;
		}
		elsif($query_id =~ /\S+\_(\S+)$/)
		{
			$rRNA_type = $1;
		}
		next if($rRNA_type eq '-|');
		my @tmp = ($subject_length, $subject_start, $subject_end, $rRNA_type, $positive);
		push(@{$rRNA{$subject_id}}, \@tmp);
	};
	close TABLE;
}

#print Dumper(\%rRNA);
##if need add output the gff format file, it will be used!
#print "seqname\tsource\tfeature\tstart\tend\tscore\t+/-\tframe\tattribute\n";
foreach my $scaf (sort {$a cmp $b} (keys %rRNA))
{
	my $filter = &merge_rrna($rRNA{$scaf});
	my @filter_rRNA = @{$filter};
	#print Dumper(\@filter_rRNA);
	for(my $index=0; $index<@filter_rRNA; ++$index)
	{
		next if (!defined($filter_rRNA[$index]));
		my @tmp = @{$filter_rRNA[$index]};
		$tmp[3] = lc($tmp[3]);
		if($tmp[3] eq '5s')
		{
			++$count_5s;
			$length_5s += ($tmp[2]-$tmp[1]+1);

		}
		elsif($tmp[3] eq '16s')
		{
			++$count_16s;
			$length_16s += ($tmp[2]-$tmp[1]+1);
		}
		elsif($tmp[3] eq '23s')
		{
			++$count_23s;
			$length_23s += ($tmp[2]-$tmp[1]+1);
		}
		else
		{
			warn("unknown attribute!\n");
		}	
		#print "$scaf\tblastn\trRNA\t$tmp[1]\t$tmp[2]\t$tmp[4]\t--\t--\t$tmp[3]_rRNA\n"
	}
}
##
my $total_length = &readfasta($sequence);
$length_5s ||= 0;
$length_16s ||= 0;
$length_23s ||= 0;
my $total_ratio = sprintf("%.4f", 100*($length_5s+$length_16s+$length_23s)/$total_length);
##stat the info of rRNA
##print "Type\tCopy#\tAvg_Len\tTotal_Len\t% in Genome\n";
#print "rRNA_ho\t";
if (defined $count_5s)
{
	my $temp_avg = $length_5s/$count_5s;
	&comma_add (0, $count_5s, $temp_avg, $length_5s);
	print "rRNA_ho\t5s\t$count_5s","\t", $temp_avg,"\t",$length_5s,"\n";
	$rRNA_num += $count_5s;
}
else
{
	print  "rRNA_ho\t5s\t0","\t", 0,"\t",0, "\n";
}
if (defined $count_16s)
{
	my $temp_avg = $length_16s/$count_16s;
	&comma_add (0, $count_16s, $temp_avg, $length_16s);
	&comma_add (4, $total_ratio);
	print "\t","16s\t$count_16s","\t", $temp_avg,"\t",$length_16s, "\t", $total_ratio, "\n";
	$rRNA_num += $count_16s;
}
else
{
	&comma_add (4, $total_ratio);
	print "\t", "16s\t0","\t", 0,"\t",0, "\t", $total_ratio, "\n";
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
	print "\t", "23s\t0","\t", 0,"\t",0, "\t", "\n";
}

print "$rRNA_num\n";

##########################################sub routine
sub merge_rrna
{
	my $ref = shift;
	my @sub_rRNA = @{$ref};
	my $size = @sub_rRNA;
	foreach (@sub_rRNA)
	{
		#	next if(!defined $_);
		#	print "@{$_}", "\n";
	}
	for(my $index=0; $index < $size; ++$index)
	{
		next if(!defined($sub_rRNA[$index]));
		for(my $loop=0; $loop < $size; ++$loop)
		{
			next if ($loop == $index);
			next if (!defined($sub_rRNA[$index]));
			next if (!defined($sub_rRNA[$loop]));
			my @outer = @{$sub_rRNA[$index]};
			my @inner = @{$sub_rRNA[$loop]};
			if($outer[3] eq $inner[3] and $outer[4] eq $inner[4])
			{
				if($outer[1] == $inner[1])
				{
					$outer[2] >= $inner[2] ? (delete($sub_rRNA[$loop])) : (delete($sub_rRNA[$index]));
				}
				elsif($outer[1] > $inner[1])
				{
					if($outer[2] <= $inner[2])
					{
						delete($sub_rRNA[$index]);
					}
					else
					{
						$inner[2] = $outer[2];
					}
				}
				else
				{
					if($inner[2] <= $outer[2])
					{
						delete($sub_rRNA[$loop]);
					}
					else
					{
						$outer[2] = $inner[2];
					}
				}
			}
		}
	}
#	foreach  (@sub_rRNA)
#	{
#		next if(!defined($_));
		#	print $_, "\n";
		#	print "@{$_}", "\n";
#	}
	return \@sub_rRNA;
}
##
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

##
sub usage
{
	print 
	("\n
		Usage:
		perl $0 <options> 
		Options:
		--rRNA<str> 		rRNA result of tab files
		--threshold[f]	ration of align length of ref length, default is 0.8
		--sequence<str> 	sequence of fa file
		--help			get the help information
		\n"
	);

	exit(-1);
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
##parse the gff result by denovo rRNA
