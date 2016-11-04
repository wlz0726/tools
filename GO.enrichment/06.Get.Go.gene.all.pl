my $in="result.04.txt.fdr.name";
my $out="$0.out";

my %h;
open(IN,"Gene2GoID.cattle.table.go2gene");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    my $go=shift(@a);
    my $gene=join("\t",@a);
    $h{$go}=$gene;
}
close IN;

my %interest;
open(IN,"in.txt.03.out");
while(<IN>){
    chomp;
    $interest{$_}++;
}
close IN;

my %gene;
open(IN,"/home/share/user/user104/projects/yak/angsd6.SelectiveSweeps/01.beagle/03.nsl/03.5.annot/05.gene.name/yak.gene.20110308.pep.swissprot.blast.best.01");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    $gene{$a[0]}=$_;
}
close IN;

open(IN,"/home/share/user/user104/projects/yak/angsd6.SelectiveSweeps/01.beagle/03.nsl/03.5.annot/05.gene.name/yak.gene.20110308.pep.trembl.blast.best.01");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    next if(exists $gene{$a[0]});
    $gene{$a[0]}=$_;
}
close IN;

open(IN,"$in");
open(OUT,"> $out");
<IN>;
while(<IN>){
    next if(/list1InGO/);
    chomp;
    my @a=split("\t");
    my $go=$a[0];
    my $print=$_;
    
    my $gene=$h{$go};
    my @b=split("\t",$gene);
    foreach my $b(@b){
        if(exists $interest{$b}){
            if(exists $gene{$b}){
	print OUT "$gene{$b}\t$print\n";
            }else{
	print OUT "$b\t-\t-\t-\t$print\n";
            }
        }
    }
    
    
}
close IN;
close OUT;
