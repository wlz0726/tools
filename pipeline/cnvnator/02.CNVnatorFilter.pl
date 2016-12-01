
my $dir="01.cnv.V4.seperate.pl.300.out";
die "01.cnv.V4.seperate.pl.1000.out\n"unless $dir;

$dir =~ /.seperate.pl.(\d+).out/;
my $id=$1;
my $out="$0.$id.out";
`mkdir $out`;

open(O,"> $0.$id.sh");
my @f=<$dir/CNV/*cnv>;
foreach my $f(@f){
    $f =~ /01.cnv.V4.seperate.pl.(\d+).out\/CNV\/(\w+)\.cnv/;
    
    my $sample_id=$2;
    print O "perl CNVnatorFilter.pl $f $out/$sample_id.filter1;\n";
}
close O;
