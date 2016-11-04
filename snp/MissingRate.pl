my $f =shift;
my $out=shift;

my %pop;
open(I,"Ind.list"); # SampleID Popinfo
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $pop{$a[0]}=$a[1];
}
close I;

my %p;
my %out;
my @id;
open(I,"zcat $f|");
open(O1,"|gzip -c > $out.Missinfo.gz");
print O1 "Chr Pos rs_id Miss_AC BRM FLV GIR HOL JBC JER LIM LQC LXC NEL NYC QCC RAN YBC YNC\n";
while(<I>){
    chomp;
    next if(/^\#\#/);
    if(/^\#/){
	@id=split(/\s+/);
	next;
    }
    my @a=split(/\s+/);
    my $chr=$a[0];
    my $pos=$a[1];
    my $rsid=$a[2];
    for(my $i=9;$i<@a;$i++){
	my $id=$id[$i];
	my $pop=$pop{$id};
	my $gt=$a[$i];
	$p{$pop}{$pos}{SampleNum}+=2;
	if($gt =~/\.\/\./){
	    $p{$pop}{$pos}{miss}+=2;
	}elsif($gt =~ /0\/0/){
	    $p{$pop}{$pos}{ref}+=2;
	}elsif($gt =~ /0\/[^0]/){
	    $p{$pop}{$pos}{alt}+=1;
	    $p{$pop}{$pos}{ref}+=1;
	}else{
	    $p{$pop}{$pos}{alt}+=2;
	}
    }
    my $all_miss=0;
    my $all_alt=0;
    my @tmp1; # miss
    foreach my $k(sort keys %p){
	my $miss=0;
	$miss+=$p{$k}{$pos}{miss};
	my $total=$p{$k}{$pos}{SampleNum};
	my $miss_rate=$miss/$total;
	push(@tmp1,$miss_rate);
		
	$all_miss +=$miss;
    }
    my $all_miss_rate=$all_miss/302;
    print O1 "$chr\t$pos\t$rsid\t$all_miss_rate\t",join("\t",@tmp1),"\n";
}
close I;
close O1;


