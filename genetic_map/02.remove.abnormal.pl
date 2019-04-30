my $out="$0.out";
`mkdir $out`;

my @f=<01.rsIDPos.pl.out/*gz>;
foreach my $f(@f){
    $f =~ /\/([^\/]+).gz/;
    my $chr=$1;
    print "perl remove.abnormal.pl $f $out/$chr.gz;\n";
}
