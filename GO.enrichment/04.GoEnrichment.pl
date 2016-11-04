use strict;
use warnings;

my $list1="in.txt.03.out";  # interest gene list
my $list2="Gene2GoID.cattle.table.genelist"; # all gene list

my $table="Gene2GoID.cattle.table";
my $obo="gene_ontology.obo";

my $out="result.04.txt";
open(T,"> $out")||die"$!\n";
#print T "GO\tType\tFunction\tx-2\tfdr\tFisher\tfdr\tlist1InGO\tlist1OutGO\tlist1Percent\tlist2InGO\tlist2OutGO\tlist2Percent\tPercentDiff\n";
print T "GO\tx2\tlist1InGO\tlist1OutGO\tlist2InGO\tlist2OutGO\n";
close T;
my $Rscript="runR.04.r";

my %GOname=&readobo($obo);

my %GO1=&readlist($list1,$table);
my $num1=`wc -l $list1`;
$num1=~/^(\d+)/;
$num1=$1;
print "1:$num1\n";
$num1=num($list1,$table);

my %GO2=&readlist($list2,$table);
my $num2=`wc -l $list2`;
$num2=~/^(\d+)/;
$num2=$1;
print "2:$num2\n";
$num2=num($list2,$table);

open(R,"> $Rscript");
open(OUT,"> $0.GoName");
foreach my $go(sort keys %GOname){
    next unless(exists $GO1{$go} || exists $GO2{$go});
    my $a=keys %{$GO1{$go}};
    next if($a<1);
    my $b=$num1-$a;
    my $c=keys %{$GO2{$go}};
    my $d=$num2-$c;
    print OUT "$go\t$GOname{$go}{namespace}\t$GOname{$go}{name}\n";
    print R "
a=matrix(c($a,$b,$c,$d),ncol=2);
b=chisq.test(a);
line=paste(\"$go\t\",b\$p.value,\"\t$a\t$b\t$c\t$d\");
write.table(line,file=\"$out\",append = TRUE,row.names=FALSE,col.names=FALSE,quote = FALSE);
";
}
close R;
close OUT;

`Rscript runR.04.r`;

sub num{
    my ($file,$table)=@_;
    open(F,$table)||die "$!";
    my $number=0;
    my %test;
    while(<F>){
        chomp;
        next if(/^\s*$/);
        my @a=split("\t",$_);
        $test{$a[0]}++;
    }
    close F;
    open(G,"< $file");
    while (<G>) {
        chomp;
        my @a=split(/\s+/);
        next if(!exists $test{$a[0]});
        $number++;
    }
    close G;
    return $number;
}

sub readlist{
    my ($file,$table)=@_;
    open(G,"< $file");
    my %go;
    while (<G>) {
        chomp;
        my @a=split(/\s+/);
        $go{$a[0]}="TRUE";
    }
    close G;
    my %r;
    open(F,$table)||die "$!";
    while(<F>){
        chomp;
        next if(/^\s*$/);
        my @a=split("\t",$_);
        next if(!exists $go{$a[0]});
        for(my $i=1;$i<@a;$i++){
            if($a[$i]=~m/GO/){
	$r{$a[$i]}{$a[0]}++;
            }
        }
    }
    close(F);
    return %r;
}

sub readobo{
    my $file=shift;
    my %r;
    open(F,$file)||die "$!";
    while(<F>){
        chomp;
        if(/^\[Term\]$/){
            my $idline=<F>;
            chomp $idline;
            $idline=~s/id: //g;
            
            my $nameline=<F>;
            chomp $nameline;
            $nameline=~s/name: //g;
            
            my $namespaceline=<F>;
            chomp $namespaceline;
            $namespaceline=~s/namespace: //g;
            $r{$idline}{name}=$nameline;
            $r{$idline}{namespace}=$namespaceline;
        }
    }
    close(F);
    #print scalar(keys %r);
    #die;
    return %r;
}
