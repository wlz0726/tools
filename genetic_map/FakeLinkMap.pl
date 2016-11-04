# output the fake linkage map with linearity not too far away (with a block)
# remove tri-allele; 
# tag in the fifth column represents:
# "true" : from the true linkage map
# "beyond_left/beyond_right": left/right side of the true linkage map
# "middle": in the middle of true linkage map
# "middle_same_cM": between two postions with the same cM value



my $out="$0.out";
`mkdir $out`;
my $f=shift; # input

$f =~/\/final.gatk.snp.Chr(.*).VQSR.vcf.gz/; # SNP file in vcf file
my $chr=$1;
my $link="02.remove.abnormal.pl.out/$1.gz";  # link file with: chr pos rs_id Position_cM

my %link;
open(I,"zcat $link|"); #######3 read linkage map
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $link{$a[1]}=$a[3]; # pos cM
}
close I;

open(I,"zcat $f|"); # read SNP file
open(O,"|gzip -c > $out/$chr.FakeLinkageMap.gz");
while(<I>){
    chomp;
    next if(/^\#/);
    my @a=split(/\s+/);
    #next if(length($a[3])>1);
    #next if(length($a[4])>1); # rm tri-allele
    
    my $pos=$a[1];
    my $rsid=$a[2];
    
    my $left;
    my $right;
    my $fake_link;
    my $fake_link_info;
    if(exists $link{$pos}){ # exists true linkage map infomation (with tag "true" at the fourth column)
	$fake_link=$link{$pos};
	$fake_link_info="true";
    }else{
	my @b=sort{$a<=>$b} keys %link;
	my $small=$b[0];
	my $big=$b[-1];
	if($pos<$small){ # postion too small  ??? # on the left side of the linkage map (with tag "beyond_left" at the fourth column)
	    # output to 0
	    my $fl=0+(($link{$b[0]}-0)*($pos-0)/($b[0]-0));
	    $fake_link=sprintf("%.3f",$fl);
	    $fake_link_info="beyond_left";
	}elsif($pos>$big){ # postion too big  ??? # on the right side of the linkage map (with tag "beyond_left" at the fourth column)
	    # equal to the biggest
	    $fake_link=$link{$b[-1]};
	    $fake_link_info="beyond_right";
            #my $fl=$link{$b[-1]}+(($link{$b[-1]}-$link{$b[-2]})*($pos-$big)/($b[-1]-$b[-2]));
	    #$fake_link=sprintf("%.3f",$fl);
	    #$fake_link_info="beyond_right";
	}else{ # pos between two sites with cM info #
	    for(my $i=0;$i+1<@b;$i++){
		my $pos1=$b[$i];
		my $pos2=$b[$i+1];
		$left =$pos-$pos1; # >0
		$right=$pos-$pos2; # <0
		if($left*$right<0){ # in the middle of pos1 and pos2 # fake linkage map using linearity
		    my $cm1=$link{$pos1};
		    my $cm2=$link{$pos2};
		    if($cm1==$cm2){
			$fake_link=$cm1;
			$fake_link_info="middle_same_cM";
		    }else{
			my $fl=$cm1+(($cm2-$cm1)*($pos-$pos1)/($pos2-$pos1)); # linear fake Position_cM
			$fake_link=sprintf("%.3f",$fl);
			$fake_link_info="middle";
		    }
		}
	    }
	}
    }
    print O "$chr\t$pos\t$rsid\t$fake_link\t$fake_link_info\n";
}
close I;
close O;


