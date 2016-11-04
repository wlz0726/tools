my $tped=shift;

open(I,"$tped");
while(<I>){
    chomp;
    my @a=split(/\s+/);
    my $anc1=$a[306];
    my $anc2=$a[307];
    if($anc1 =~/0/ && $anc2 =~/0/){
	next;
    }
    print "$_\n";
}
close I;
