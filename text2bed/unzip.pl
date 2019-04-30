my $list="part1.lanao.list";

open(I,"$list");
while(<I>){
    chomp;
    $_ =~ /\/([^\/]+).txt.gz/;
    print "zcat $_ > part1.lanao.unzip/$1;\n";
}
close I;
