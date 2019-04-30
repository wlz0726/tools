#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=2) {
	print "perl $0 <geno><chrom>\n";
	exit 0;
}
my ($in,$chrom)=@ARGV;
open FA,"/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/CNV/ref/b37/chr$chrom.fasta" or die $!;
my $chromosome=""; my $seq="";
while(<FA>){
        if(/>(\w+)/) { $chromosome=$1;  }
            else { chomp; $seq.=$_;  }
        }
        close FA;        
if($in=~/.gz/) {open IN,"zcat $in|" or die $!;}  else{open IN,$in or die $!;}
#my %newfa=();
#my $back_seq=$seq;
my $new_seq;my $m_pos=0;my $len=length($seq);
while(<IN>){
chomp;
my ($chr,$pos,$genotype)=(split(/\s+/,$_))[0,1,2];
next unless($chr eq $chrom);
#    my $ref=substr($fa{$chr},$pos-1,1);
#    if($ref=~/[a|t|c|g]/) {$ref=~tr/atcg/ATCG/;}
my $short=GENO($genotype);
if($m_pos==0)     {
    $new_seq=substr($seq,0,$pos-1);
    $new_seq.=$short;$m_pos=$pos; next;
}
$new_seq.=substr($seq,$m_pos,$pos-$m_pos-1);$new_seq.=$short;
$m_pos=$pos;    
}

$new_seq.=substr($seq,$m_pos);
#===============
my $check_len=length $new_seq;
if($check_len!=$len) {die "something is wrong\t$len\t$seq\t$check_len\t$new_seq\n";}
#================
print "@"."$chrom\n";
Display_seq(\$new_seq); 
print "$new_seq"."+\n";
my $qulity="@" x $len;
Display_seq(\$qulity);
print "$qulity";
close IN;

sub GENO{
my $geno    =shift;
my ($s1,$s2)=(substr($geno,0,1),substr($geno,1,1));
my $type='hom';my $geno_s;
if($s1 eq $s2) {$type='hom';} else {$type="het";}
if($type eq "het"){
    if($geno=~/AC/||$geno=~/CA/){$geno_s="M";}
    elsif($geno=~/AG/||$geno=~/GA/){$geno_s="R";}
    elsif($geno=~/AT/||$geno=~/TA/){$geno_s="W";}
    elsif($geno=~/GC/||$geno=~/CG/){$geno_s="S";}
    elsif($geno=~/TC/||$geno=~/CT/){$geno_s="Y";}
    elsif($geno=~/GT/||$geno=~/TG/){$geno_s="K";}
    else{die "wrong$geno:$_\n";}
}
else{
    $geno_s=$s1;
}
return $geno_s;
}                                                    
sub Display_seq{
        my $seq_p=shift;
            my $num_line=(@_) ? shift : 50; ##set the number of charcters in each line
                my $disp;

                    $$seq_p =~ s/\s//g;
                        for (my $i=0; $i<length($$seq_p); $i+=$num_line) {
                                    $disp .= substr($$seq_p,$i,$num_line)."\n";
                                        }
                                            $$seq_p = ($disp) ?  $disp : "\n";
                                        }
