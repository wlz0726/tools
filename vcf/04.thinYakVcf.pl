my $out="$0.out";
`mkdir $out`;

my @f=<03.SNPcall.pl.out/*gz>;
open(O,"> $0.sh");
foreach my $f(@f){
    $f =~ /\/Chr(.*).vcf.gz/;
    my $chr=$1;
    print O "perl thinYakVcf.pl $f $out/$1.gt.gz;\n";
}
close O;
