my $snp_dir=shift;
die "$0 snp_dir\n"unless $snp_dir;

open(O,"|gzip -c > $snp_dir.vcf.gz");
open(I,"zcat $snp_dir/Chr1.vcf.gz|");
while(<I>){
    if(/^\#/){
       print O "$_";
   }
}
close I;

for(my $i=1;$i<=29;$i++){
    open(I,"zcat $snp_dir/Chr$i.vcf.gz|");
    while(<I>){
	next if(/^\#/);
	chomp;
	my @a=split(/\s+/);
	$a[0] =~ s/^Chr//;
	print O join("\t",@a),"\n";
    }
}
close O;
