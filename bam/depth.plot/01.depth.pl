my $list=shift;
my $region_around=10000;
die "$0 input.region(First col scaffold635:339334-361000)\n"unless $list;


# chrlength
my %chr_length;
open(I,"/home/wanglizhong/project/02.blind_mole_rat.RATxdeR/ref/chr.length");
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $chr_length{$a[0]}=$a[1];
}
close I;

my $out="$0.$list";
`mkdir $out`unless -e $out;

open(O,"> $0.$list.sh");
open(I,"$list");
while(<I>){
    chomp;
    next if(/^\#/);
    my @a=split(/\s+/);
    $a[0] =~ /(.*):(\d+)-(\d+)/;
    my $chr=$1;
    my $start=$2;
    my $end=$3;
    my $chr_len=$chr_length{$chr};
    
    my ($start2,$end2);
    if($start-$region_around>=0){
	$start2=$start-$region_around;
    }else{
	$start2=0;
    }

    if($end+$region_around<=$chr_len){
	$end2=$end+$region_around;
    }else{
	$end2=$chr_len;
    }
    
    my $new_id="$chr:$start2-$end2";
    my $outid="$chr-$start-$end";
    my $outdir="$out/$outid";
    `mkdir -p $outdir`unless -e $outdir;
    #print "$a[0]\t$new_id\n";
    #print "$chr\t$start\t$end\t$chr_len\t$start2\t$end2\n";
    print O "/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/samtools depth -f bam.list -q 0 -Q 0 -r $new_id |gzip -c > $outdir/$outid.depth.gz;\n";
}
close I;
close O;
