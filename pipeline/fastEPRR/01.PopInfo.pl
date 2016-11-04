open(I,"sample_label.rename.ids"); # only need two cols: id  population 
my %h;
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $h{$a[1]}{$a[0]}++;
}
close I;

foreach my $k1(keys %h){
    my $num=keys %{$h{$k1}};
    next if $num<5;
    my $outdir="Pop_$k1";
    `mkdir $outdir` unless (-e "Pop_$k1");
    open(O,"> Pop_$k1/$k1.txt");
    foreach my $k2(sort keys %{$h{$k1}}){
	print O "$k2\n";
    }
    close O;
}
