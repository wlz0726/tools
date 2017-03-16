my $in=shift;

open(I,"zcat $in|");
my $i=0;
while(<I>){
    chomp;
    $i++;
}
close I;

my $num=$i/4;
print "$in\t$num\n";
