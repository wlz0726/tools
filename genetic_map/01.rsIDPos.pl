open(I,"linkage-map-rename.csv");
<I>;
my %link_map;
while(<I>){
    chomp;
    my @a=split(/,/);
    next if($a[10] =~ /\d+/);
    if($a[4] =~ /SNP/){
	$link_map{$a[0]}{$a[1]}=$a[7]; # chr rsID - Pos_cM
    }
}
close I;

open(I,"dbsnp.vcf");
my %out;
while(<I>){
    chomp;
    next if(/^\#/);
    my @a=split(/\s+/);
    next if(length($a[3])>1);
    next if(length($a[4])>1);
    $a[0] =~ /Chr(.*)/;
    my $chr=$1;
    my $pos=$a[1];
    my $rs=$a[2];
    my $before="NA"; 
    my $after= "NA";
    my %tmp;
    if(exists $link_map{$chr}{$rs}){
	#print O "$chr\t$pos\t$rs\t$link_map{$chr}{$rs}\n";
	$out{$chr}{$pos}="$rs\t$link_map{$chr}{$rs}";
    }
}
close I;

my $out="$0.out";
`mkdir $out`;
foreach my $k1(keys %out){
    open(O,"|gzip -c > $out/$k1.gz");
    foreach my $k2(sort{$a<=>$b} keys %{$out{$k1}}){
	print O "$k1\t$k2\t$out{$k1}{$k2}\n";
    }
    close O;
}
