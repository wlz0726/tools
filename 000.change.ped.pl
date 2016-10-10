my $ped=shift;
open(IN,"$ped");
open(OUT,"> $ped.ped");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $a[5] ="0";
    print OUT join(" ",@a),"\n";
}
close IN;
close OUT;
