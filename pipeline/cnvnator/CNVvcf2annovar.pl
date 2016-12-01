my $file=shift;

open IN,$file or die $!;
while (<IN>)
{
	chomp;
    next if(/#/);
    my @s=split;
    my ($chr,$pos,$info)=(@s)[0,1,7];
    my $end="";
    my $type="";
    if(/END=(\d+)/) {$end=$1;}
    if(/SVTYPE=(\w+)\;/){$type=$1;}
    print "$chr\t$pos\t$end\t0\t0\t$info\n";

}
close IN;
