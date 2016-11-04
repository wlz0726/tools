my $tped=shift;
die "$0 ../*tped\n"unless $tped;

$tped =~ /..\/(.*).tped/;
my $prefix=$1;
my $id=$1;
`ln -s $tped .`;
`ln -s ../final_ance.rename.tfam $prefix.tfam`;

#open(OUT,"> $0.$prefix.sh");
#print OUT "perl 5.ChangeMap.pl $prefix.map\n";
#close OUT;
`perl 1.runPlink.pl $prefix`;

`perl 4.RunPCA.pl $prefix`;

`perl 8.AdmixtureForOldVCF.pl $prefix`;

#`perl 10.IBS.Het.pl $prefix.2`;
#`perl 10.IBS.Het.pl $prefix.maf0.05`;
#`perl 11.KING.pl $prefix.2`;
#`perl 11.KING.pl $prefix.maf0.05`;
#`perl 12.haploview.LD.pl $prefix`;
