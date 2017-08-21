my $file=shift;

open IN,$file or die $!;
while (<IN>)
{
	chomp;
	my @arr=split;
	next if($_ =~ /^CNV_type/);
	my ($chr,$start,$end);
	if($arr[1]=~/^([^:]+):(\d+)-(\d+)$/)
	{
		$chr=$1;$start=$2;$end=$3;
	}
	$type=$arr[0];
	$type='amplification' if($type eq 'duplication');
	print "$chr\t$start\t$end\t0\t0\tSize=$arr[2];Copy_ratio=$arr[3];Type=$type\n";
}
close IN;
