my $repeat_mask="RepeatMasker.region2.gz";  # chr start_pos end_pos(bed file)

my $out="$0.out";
`mkdir $out`;
my %h;
my $line=1;
open(I,"zcat $repeat_mask|");
<I>;  ############################ skip head/firest line
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $a[0] =~ /chr(.*)/;
    my $chr=$1;
    if($chr =~ /[\dX]+/){
	$h{$chr}{$line}{start}=$a[1];
	$h{$chr}{$line}{end}=$a[2];
	$line++;
    }
}
close I;
print "read complete\n";
foreach my $k1(sort keys %h){
    open(O,"|gzip -c > $out/$k1.pos.gz");
    foreach my $k2(sort{$a<=>$b} keys %{$h{$k1}}){
	my $start=$h{$k1}{$k2}{start};
	my $end=$h{$k1}{$k2}{end};
	print O "$start\t$end\n";
    }
    print "$out/$k1.pos.gz complete\n";
    close O;
}
