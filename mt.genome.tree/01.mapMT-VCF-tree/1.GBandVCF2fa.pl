use strict;
use warnings;

my ($inputgb,$inputvcf)=@ARGV;
my %h;
open (F,"$inputgb")||die"$!";
my $line=0;
while (<F>) {
    chomp;
    if (/^\s+(D-loop|rRNA|tRNA|CDS)\D+(\d+)\.\.(\d+)/){
        my $type=$1;
        my $start=$2;
        my $end=$3;
        $line++;
        my $j=0;
        for (my $i=$start;$i<=$end;$i++){
            my $newtype;
            if ($type eq 'CDS'){
        next if ($i<$start+3 || $i>$end-3);
        $j++;
        $newtype="codon.$j";
            }else{
        $newtype=$type;
            }
            $h{$i}{$line}=$newtype;
            $j=0 if $j == 3;
        }
    }
}

open (O,">$0.list")||die"$!";
for my $k (sort{$a<=>$b} keys %h){
    print O "$k\t";
    my @k2=sort{$a<=>$b} keys %{$h{$k}};
    #print "$k\n" if scalar(@k2)>1;
    for my $k2 (@k2){
        print O "$h{$k}{$k2}\t";
    }
    print O "\n";
}
close O;
#my %flt;

my %seq;
my @id;
open (F,"$inputvcf")||die"$!";
while (<F>) {
    chomp;
    next if /^##/;
    my @a=split(/\t/,$_);
    if (/^#/){
        $_=~s/bowtie2\///g;
        $_=~s/\.sort.bam//g;
        @id=split(/\t/,$_);
        next;
    }
    next if (length($a[3])>1 || length($a[4])>1);
    next if ! exists $h{$a[1]};
    #print "$_\n";exit;
    for my $key2 (sort keys %{$h{$a[1]}}){
        my $type=$h{$a[1]}{$key2};
        for (my $i=9;$i<@a;$i++){
            my $id=$id[$i];
            my ($word,$dp);
            my @b=split(/\:/,$a[$i]);
            if ($a[$i] =~ /^\d\/\d\:/){
        my $dp=$b[2];
        #print "$a[0]\t$a[1]\t$dp\n$a[$i]\n",join("\n",@b),"\n";exit;
        if ($dp < 3){
            $word='-';
        }else{
            if($a[$i]=~/^0\/0/){
                $word=$a[3];
            }elsif($a[$i]=~/^(1\/1|0\/1)/){
                $word=$a[4];
            }else{
                die "wrong $a[0]\t$a[1]\t$a[$i]\n";
            }
        }
            }else{
        my $dp=$b[1];
        if ($dp<3){
            $word='-';
        }else{
            $word=$a[3];
        }
            }
            $seq{$type}{$id}{$a[1]}=$word;
            #print "\$seq{$type}{$id}{$a[1]}=$word\n";
        if ($dp < 3){
            $word='-';
        }else{
            if($a[$i]=~/^0\/0/){
                $word=$a[3];
            }elsif($a[$i]=~/^(1\/1|0\/1)/){
                $word=$a[4];
            }else{
                die "wrong $a[0]\t$a[1]\t$a[$i]\n";
            }
        }
            }else{
        my $dp=$b[1];
        if ($dp<3){
            $word='-';
        }else{
            $word=$a[3];
        }
            }
            $seq{$type}{$id}{$a[1]}=$word;
            #print "\$seq{$type}{$id}{$a[1]}=$word\n";
        }
    }
}
close F;

for my $seqtype (sort keys %seq){
    open (O,">2.$seqtype.fas");
    for my $species (sort keys %{$seq{$seqtype}}){
        print O ">$species\n";
        for my $pos (sort{$a<=>$b} keys %{$seq{$seqtype}{$species}}){
            print O "$seq{$seqtype}{$species}{$pos}";
        }
        print O "\n";
    }
    close O;
}
