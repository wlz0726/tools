my $cnv=shift;

open IN,$cnv or die $!;
while(<IN>)
{
	chomp;
	next if($_ =~ /^Chromosome/);
	my @arr=split /\t/,$_;
	my $chr=$arr[0];
	$chr='chrX' if($chr eq '23');
	$chr='chrY' if($chr eq '24');
	$chr="chr$i" if($chr !~ /^chr/);
	my $ratio=$arr[3];
	my $type;
	if($ratio<0.76)
	{
		$type='deletion';
	}
	elsif($ratio>1.24)
	{
		$type='amplification';
	}
	print "$chr\t$arr[1]\t$arr[2]\t0\t0\tCopy_ratio=$arr[3];p-value=$arr[4];Type=$type\n";
}
close IN;
