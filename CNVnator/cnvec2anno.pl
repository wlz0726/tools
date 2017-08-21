my $cnv=shift;
open IN,$cnv or die $!;
while(<IN>)
{
	chomp;
	next if($_ =~ /\bprobe/);
	my ($chr,$start,$end,$ratio)=(split /\t/,$_)[0,1,2,3];
	$chr="chr$i" if($chr !~ /^chr/);
	my $type;
	if($ratio<0.76)
	{
		$type='deletion';
	}
	elsif($ratio>1.24)
	{
		$type='amplification';
	}
	print "$chr\t$start\t$end\t0\t0\tCopy_ratio=$ratio;Type=$type\n";
}
close IN;
