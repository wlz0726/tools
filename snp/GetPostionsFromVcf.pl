# change Chr1 to 1; rename chr name
my ($snp_pos,$phased_vcf,$outprefix)=@ARGV;

my %snp;
open(I,"zcat $snp_pos|");
while(<I>){
    chomp;
    my ($chr,$pos)=(split(/\s+/,$_))[0,1];
    my $key="$chr,$pos";
    $snp{$key}++;
}
close I;

open(I,"zcat $phased_vcf|");
open(O,"|gzip -c > $outprefix.vcf.gz");
open(LOG,">$outprefix.vcf.gz.log");
my $snpnum=0;
while(<I>){
    chomp;
    if(/\#/){
	print O "$_\n";
	next;
    }
    my @a=split(/\s+/);
    my ($chr,$pos)=@a[0,1];
    my $key="$chr,$pos";
    next if(length($a[4])>1);
    if(exists $snp{$key}){
	$snpnum++;
	$a[0] =~ s/^Chr//;
	$a[5]=".";
	$a[6]=".";
	$a[7]=".";
	$a[8]="GT";
	for(my $i=9;$i<@a;$i++){
	    $a[$i] =~ s/^(.\/.):.*/$1/;
	}
	print O join("\t",@a),"\n";
    }
}
close I;

$outprefix =~ /\/(.*)/;
my $chr=$1;
print LOG "$chr\t$snpnum\n";
close LOG;
