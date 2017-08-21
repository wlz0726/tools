my $cnvf=shift;

print "Chromosome\tStart\tEnd\tCopy ratio\tp-value\tNormal count\tTumor count\n";

open IN,$cnvf or die $!;
while (<IN>)
{
	chomp;
	if($_ =~ /^Chromosome/)
	{
		next;
	}
	my @arr=split /\t/,$_;
	my $chr=$arr[0];
	$chr='chrX' if($chr =~ /23$/);
	$chr="chr$chr" if($chr !~ /^chr/);
	print "$chr\t$arr[1]\t$arr[2]\t$arr[3]\t$arr[4]\t$arr[5]\t$arr[6]\n";
}
close IN;
