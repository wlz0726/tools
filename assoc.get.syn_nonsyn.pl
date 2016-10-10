#! /usr/bin/perl
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;

sub translate_nucl{
    my $seq=shift;
    my $seq_obj=Bio::Seq->new(-seq=>$seq,-alphabet=>'dna');
    my $pro=$seq_obj->translate;
    $pro=$pro->seq;
    return($pro);
}


my $location_file=shift;
die "$0 vcffile\n" unless $location_file;
my $gff="/home/share/data/genome/Bos_grunniens/00.Genome/YakGenome1.1/02.Annotation/01.gene/yak.gene/yak.gene.20110308.fixed.gff";
my $genome="/home/share/user/user104/projects/yak/yakres.snp.20130928/ref/yak0803_v2.sca.break.fa.filter2K.fa";


my %loc;
open(IN,"< $gff")||die("$!\n");
my $line=0;
while (<IN>) {
    chomp;
    next if(/mRNA/);
    my @a=split(/\s+/);
    $loc{$a[0]}{$line}{start}=$a[3];
    $loc{$a[0]}{$line}{end}=$a[4];
    #$a[7]="0" if($a[7] eq ".");
    die if($a[7] eq ".");
    $loc{$a[0]}{$line}{phase}=$a[7];
    $loc{$a[0]}{$line}{strand}=$a[6];
    $a[8]=~/=([^;]+);/;
    my $name=$1;
    $loc{$a[0]}{$line}{name}=$name;
    $line++;
}
close IN;

print STDERR "STEP 1/4 $gff loaded...\n";

my %hash;
open(IN,"< $location_file")||die("$!\n");
while (<IN>) {
    chomp;
    next if(/^#/);
    my @a=split(/\s+/);
    $hash{$a[0]}{$a[1]}{content}=$_;
    $hash{$a[0]}{$a[1]}{Ref}=$a[3];
    $hash{$a[0]}{$a[1]}{Rep}=$a[4];
}
close IN;

print STDERR "STEP 2/4 $location_file loaded...\n";

my %analyse;
#open(O2,"> gene.txt");
foreach my $chr(keys %loc){
    next if(!exists $hash{$chr});
    my @a=sort{$a<=>$b} keys %{$hash{$chr}};
    #my $debug=@a;
    #next if($debug==0);
    my $i=0;
    foreach my $line(sort{$loc{$chr}{$a}{start}<=>$loc{$chr}{$b}{start}} keys %{$loc{$chr}}){
        #print "DEBUG: $a[$i]\t$a[-1]\n";
        die "$chr\t$loc{$chr}{$line}{start}\t$loc{$chr}{$line}{end}\n$i\n@a\n" if(!$a[$i]||!$a[-1]);
        next if($loc{$chr}{$line}{end}   <= $a[$i]);
        last if($loc{$chr}{$line}{start} >= $a[-1]);
        my $temp=$i;
        for(my $j=$i;$j<@a;$j++){
            last if($loc{$chr}{$line}{end}   <= $a[$j]);
            next if($loc{$chr}{$line}{start} >= $a[$j]);
            #print O1 "$chr\t$a[$j]\t$hash{$chr}{$a[$j]}\tvalidate\t$loc{$chr}{$line}{start}\t$loc{$chr}{$line}{end}\n";
            #print O2 "$hash{$chr}{$a[$j]}\n";
            my $phase = $loc{$chr}{$line}{phase};
            my $start = $loc{$chr}{$line}{start};
            my $end   = $loc{$chr}{$line}{end};
            if($loc{$chr}{$line}{strand} eq "+"){
	my $s=($a[$j]-($start+$phase))%3;
	$analyse{$chr}{$a[$j]}{start}  = $s;
	$analyse{$chr}{$a[$j]}{gs}     = $loc{$chr}{$line}{start};
	$analyse{$chr}{$a[$j]}{ge}     = $loc{$chr}{$line}{end};
	$analyse{$chr}{$a[$j]}{Ref}    = $hash{$chr}{$a[$j]}{Ref};
	$analyse{$chr}{$a[$j]}{Rep}    = $hash{$chr}{$a[$j]}{Rep};
	$analyse{$chr}{$a[$j]}{strand} = $loc{$chr}{$line}{strand};
	$analyse{$chr}{$a[$j]}{name}  =  $loc{$chr}{$line}{name};
            }
            elsif ($loc{$chr}{$line}{strand} eq "-") {
	my $s=($end-$phase-$a[$j])%3;
	$analyse{$chr}{$a[$j]}{start}  = $s;
	$analyse{$chr}{$a[$j]}{gs}     = $loc{$chr}{$line}{start};
	$analyse{$chr}{$a[$j]}{ge}     = $loc{$chr}{$line}{end};
	$analyse{$chr}{$a[$j]}{Ref}    = $hash{$chr}{$a[$j]}{Ref};
	$analyse{$chr}{$a[$j]}{Rep}    = $hash{$chr}{$a[$j]}{Rep};
	$analyse{$chr}{$a[$j]}{strand} = $loc{$chr}{$line}{strand};
	$analyse{$chr}{$a[$j]}{name}   = $loc{$chr}{$line}{name};
            }

            $temp=$j;
        }
        $i=$temp;
    }
}
#close O2;
print STDERR "STEP 3/4 Analysis complete...\n";

open(O,"> error.log");
my $fa=Bio::SeqIO->new(-file=>$genome,-format=>'fasta');
while(my $seq=$fa->next_seq){
    my $chr=$seq->id;
    next if(!exists $analyse{$chr});
    my $seq=$seq->seq;
    my $light="OFF";
    foreach my $pos(sort {$a<=>$b} keys %{$analyse{$chr}}){
        if($analyse{$chr}{$pos}{strand} eq "+"){
            my $s=$analyse{$chr}{$pos}{start};
            my $p=$pos-$s;
            my $subseq=substr($seq,$p-1,3);
            my $validate=substr($subseq,$s,1);
            $light="ON" if($validate eq $analyse{$chr}{$pos}{Ref});
            if($light eq "OFF"){
	my $temp=substr($seq,$pos-1,1);
	print O "$hash{$chr}{$pos}{content}\n";
	print O "$temp\n";
	print O "$analyse{$chr}{$pos}{strand}\t$analyse{$chr}{$pos}{Ref}\t$analyse{$chr}{$pos}{Rep}\t$analyse{$chr}{$pos}{start}\n";
            }
            my $amio=translate_nucl($subseq);
            if($amio eq "*" && $analyse{$chr}{$pos}{ge}-$pos>3){
	#next if($analyse{$chr}{$pos}{ge}-$pos>3);
	print STDERR "ERROR detected...\n";
            }
            my @newseq=split(//,$subseq);
            $newseq[$s]=$analyse{$chr}{$pos}{Rep};
            my $new_seq=join("",@newseq);
            my $new_amio=translate_nucl($new_seq);
            my $status="NULL";
            my $special="NULL";
            #print "#$light\t*$subseq\t$amio\t->\t$new_amio\t$analyse{$chr}{$pos}{name}\t$pos\t$analyse{$chr}{$pos}{strand}\t$analyse{$chr}{$pos}{gs}\t$analyse{$chr}{$pos}{ge}\t*$s\t*$validate\t*$analyse{$chr}{$pos}{Ref}\t*$analyse{$chr}{$pos}{Rep}\n";
            if($amio eq $new_amio){
	$status = "synonymous";
            }
            else{
	$status = "nonsynonymous";
	if($amio eq "*"){
	    $special="break_codon";
	}
	elsif($new_amio eq "*"){
	    $special="new_codon";
	}
            }
            print "$analyse{$chr}{$pos}{name}\t$chr\t$pos\t$status\t$amio\t->\t$new_amio\t|\t$analyse{$chr}{$pos}{Ref}\t->\t$analyse{$chr}{$pos}{Rep}\t$special\n";
        }
        elsif($analyse{$chr}{$pos}{strand} eq "-"){
            my $s=$analyse{$chr}{$pos}{start};
            my $p=$pos-2+$s;
            my $subseq=substr($seq,$p-1,3);
            my $validate=substr($subseq,2-$s,1);
            $light="ON" if($validate eq $analyse{$chr}{$pos}{Ref});
            if($light eq "OFF"){
	my $temp=substr($seq,$pos-1,1);
	print O "$hash{$chr}{$pos}{content}\n";
	print O "$temp\n";
	print O "$analyse{$chr}{$pos}{strand}\t$analyse{$chr}{$pos}{Ref}\t$analyse{$chr}{$pos}{Rep}\t$analyse{$chr}{$pos}{start}\n";
            }
            my $temp_seq=$subseq;
            $subseq=~tr/ATCGatcg/TAGCtagc/;
            $subseq=reverse($subseq);
            my $amio=translate_nucl($subseq);
            if($amio eq "*" && $pos-$analyse{$chr}{$pos}{gs}>3){
	#next if($pos-$analyse{$chr}{$pos}{gs}>3);
	print STDERR "ERROR detected...\n";
            }
            my @newseq=split(//,$temp_seq);
            $newseq[2-$s]=$analyse{$chr}{$pos}{Rep};
            my $new_seq=join("",@newseq);
            $new_seq=~tr/ATCGatcg/TAGCtagc/;
            $new_seq=reverse($new_seq);
            my $new_amio=translate_nucl($new_seq);
            #print "#$light\t*$subseq\t$amio\t->\t$new_amio\t$analyse{$chr}{$pos}{name}\t$pos\t$analyse{$chr}{$pos}{strand}\t$analyse{$chr}{$pos}{gs}\t$analyse{$chr}{$pos}{ge}\t*$s\t*$validate\t*$analyse{$chr}{$pos}{Ref}\t*$analyse{$chr}{$pos}{Rep}\n";
            my $status="NULL";
            my $special="NULL";
            if($amio eq $new_amio){
	$status = "synonymous";
            }
            else{
	$status = "nonsynonymous";
	if($amio eq "*"){
	    $special="break_codon";
	}
	elsif($new_amio eq "*"){
	    $special="new_codon";
	}
            }
            print "$analyse{$chr}{$pos}{name}\t$chr\t$pos\t$status\t$amio\t->\t$new_amio\t|\t$analyse{$chr}{$pos}{Ref}\t->\t$analyse{$chr}{$pos}{Rep}\t$special\n";
        }
    }
}
close O;
print STDERR "STEP 4/4 Annotation complete...\n";
