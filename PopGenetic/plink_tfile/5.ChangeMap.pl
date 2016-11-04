my $map=shift;
open(O,'>',"$map.map");
open(F,$map);
my $window=1000000;
my $count=0;
my ($prescaffold,$presite);
my ($start,$end);
while(<F>){
    chomp;
    my @a=split("\t",$_);
    $a[0]=1;
    if($count==0){
        ($prescaffold,$presite)=split(":",$a[1]);
	$a[1]="rss".$a[3];
        print O join("\t",@a),"\n";
        $count++;
    }else{
        ($scaffold,$site)=split(":",$a[1]);
        if($scaffold eq $prescaffold){
            if($count==1){
                $presite=$site;
            }else{
                $a[3]+=$start;
                $presite=$a[3];
            }
        }else{
            $count++;
            $prescaffold=$scaffold;
            $start=$presite+$window;
            $a[3]+=$start;
            $presite=$a[3];
        }
        $a[1]="rss".$a[3];
        print O join("\t",@a),"\n";
    }
}

close(F);
close O;
