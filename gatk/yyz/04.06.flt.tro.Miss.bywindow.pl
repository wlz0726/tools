use strict;
use warnings;

my ($invcf,$inindel,$outvcf,$chr,$site)=@ARGV;
die "perl $0 invcf inindel outvcf chr sitelist\n" if (! $site);
my %pos=&readsite($site);
my %dp=&readdp();
my %indel;
if (! -e "$invcf"){
    print "File not exists $invcf\nWe will miss this\n";
    exit;
}

if (-e "$inindel"){
    open (F,"zcat $inindel|");
    while (<F>) {
        chomp;
        next if /^#/;
        my @a=split(/\t/,$_);
        next if $a[6] ne "PASS";
        next if $a[0] ne $chr;
        for (my $i=$a[1]-5;$i<=$a[1]+5;$i++){
            $indel{$i}++;# if exists $pos{$i};
        }
    }
    close F;
}

my $idline="#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  Cco02   Cco03   Cfr01   Oda00   Omu01   Omu02   Omu03   Omu04   Omu05   Omu06   Omu07   Omu08   Omu09   Omu10   Omu11   Omu12   Omu13   Omu14   Ore00   Ore01   Ore02   Ore03   Ore04   Ore11   Ore12   Ore13   Ore14   Ore15   Ore17   Ore18   Ore19   Ore20";
my @id=split(/\s+/,$idline);
open (O,"|gzip -c > $outvcf");
open (F,"zcat $invcf|");
while (<F>) {
    chomp;
    next if /^#/;
    my @a=split(/\t/,$_);
    next if $a[6] ne "PASS";
    next if $a[0] ne $chr;
    next if length($a[3])>1 || length($a[4])>1;
    next if exists $indel{$a[1]};
    #next if ! exists $pos{$a[1]};
    my %miss;
    $miss{Ore}=0;
    $miss{Omu}=0;
    for (my $i=9;$i<@a;$i++){
        my $id=$id[$i];
        $id=~/^(\w\w\w)/;
        my $group=$1;
        my $dp=$dp{$id};
        my ($mindp,$maxdp)=(int($dp/3),$dp*3);
        $maxdp=int($maxdp)+1 if $maxdp>int($maxdp);
        my $iddp=0;
        if ($a[9]=~/^\d+/){
            my @info=split(/:/,$a[8]);
            my @idinfo=split(/:/,$a[9]);
            for (my $i=0;$i<@info;$i++){
	if ($info[$i] eq 'DP'){
	    $iddp=$idinfo[$i];
	}
            }
        }
        $iddp=0 if $iddp eq '.';
        if ($iddp<$mindp || $iddp>$maxdp){
            #print "$iddp\t$mindp\t$maxdp\t$dp\n";
            $a[$i]="./.";
        }
        if ($a[$i]=~/^\.\/\./){
            $a[$i]=~s/^\.\/\..*$/.\/./ or die "$a[$i]\n$_\n";
        }
        $miss{$group}++ if $a[$i]=~/^\.\/\./;
    }
    next if $miss{Ore}>2 || $miss{Omu}>2;
    print O join("\t",@a),"\n";
}
close F;
close O;

sub readsite{
    my ($in)=@_;
    my %r;
    open (S,"$in");
    while (<S>) {
        chomp;
        $r{$_}++;
    }
    close S;
    return %r;
}
sub readdp{
    my $in="00.depth.txt";
    my %r;
    open (D,"$in")||die"no $in\n";
    while (<D>) {
        chomp;
        next if /^#/;
        my @a=split(/\s+/,$_);
        $r{$a[0]}=$a[6];
    }
    close D;
    return %r;
}
