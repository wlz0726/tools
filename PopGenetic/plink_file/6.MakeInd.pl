my $ped=shift;
my $out=$ped."ind";
my $count=0;
open(O,'>'."$out");
open(F,$ped);
while(<F>){
    chomp;
    my $ind;
    
    if(/^(\S+)/){
        $ind=$1;
        $count++;
        my $species;
        if($ind=~m/^(\S)/){
            $species=$1;
            my $number=$2;
        }
        print O "$count\t$ind\t0\t0\t0\t$species\n";
    }
}
close(F);
close(O); 
