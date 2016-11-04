my $vcf=shift;
my $out=shift;
open(O,"|gzip -c > $out");
open(I,"zcat $vcf|");
while(<I>){
    chomp;
    next if(/^\#/);
    my @a=split(/\s+/);
    next if(length($a[4])>1); ########################################  skip indel
    
    my $pos=$a[1];
    my $snp_qual=$a[5]; ######################################## snp quality 30
    my $info=$a[7];
    $info =~ /^DP\=(\d*);/;
    my $dp=$1; ######################################## depth 16
    $info =~ /;MQ=([\d\.]*)$/;
    my $mq=$1; ######################################## mapping quality 30
    
    next if($snp_qual<30 || $dp <16 || $mq < 30); 
    my @b;
    my $miss=0;
    for(my $i=9;$i<@a;$i++){
	$a[$i] =~ /^(.\/.)/;
	push(@b,$1);
	if ($1 =~ /\.\/\./){
	    $miss++;
	}
    }
    next if($miss>4);
    my $alt=$a[4];
    print  O "$pos\t$alt\t",join("\t",@b),"\n";
}
close I;
close O;
