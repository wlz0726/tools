my $in=shift;
my $out=shift;

my $pre=NA;
open(I,"zcat $in|");
open(O,"|gzip -c > $out");
while(<I>){
    chomp;
    my @a=split(/\s+/);
    my $morgan=$a[3];
    if($pre eq NA){
        $pre = $morgan;
        print O "$_\n";
        next;
    }else{
        if($morgan>=$pre){
            print O "$_\n";
            $pre = $morgan;
	}else{
            #print "$a[3]\t$morgan\t$pre\n";die;
        }
    }
}
close I;
