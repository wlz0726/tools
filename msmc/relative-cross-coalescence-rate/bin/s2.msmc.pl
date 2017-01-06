#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=3) {
	print "perl $0 <poplist><chrlist><outdir>\n";
	exit 0;
}
my ($poplist,$chrlist,$outdir)=@ARGV;
#if($in=~/.gz/) {open IN,"zcat $in|" or die $!;}  else{open IN,$in or die $!;}
open IN,$poplist or die $!;
my %pop_mask=();
my %pop_vcf =();
my %pop_sam =();
#==================
open T,$chrlist or die $!;
my %chrome=();while(<T>){chomp;$chrome{$_}=1;}
close T;
#==================
if( ! -e "$outdir") {`mkdir $outdir`;}
my $pop_size=100;
while(<IN>){
    chomp;
    my ($pop)=(split)[0];
    my @a=split;shift@a;my$temp=scalar@a;
    if($temp<$pop_size) {$pop_size=$temp;}
    if($pop_size==0) {die "Notice;$_\nno sample information\n";}
    $pop_mask{$pop}="$outdir/MSMCinputfile";
    $pop_vcf{$pop} ="$outdir/MSMCinputfile";
    $pop_sam{$pop}=join":",@a;
}
my $indir="$outdir/MSMC2pop";
if( ! -e "$indir") {`mkdir $indir`;}
my %have=();
open S1,'>',"$outdir/step2_msmc_txt.sh" or die $!;
open S2,'>',"$outdir/step3_msmc_rate.sh" or die $!;
foreach my $key (keys %pop_mask){
    my $pop1=$key;
   foreach my $key2 (keys %pop_mask){
       my $pop2=$key2;
       next if($key eq $key2);
       my $a1="$key"."_$key2"; my $a2="$key2"."_$key";
       if($have{$a1}){next;}
       elsif($have{$a2}){next;}
       else{$have{$a1}=1;}
       if( -e "$indir/$a1") {;} else{mkdir "$indir/$a1";}
       my $sum_txt="";
       #=====ready input file of MSMC====
       foreach my $chr (sort keys %chrome){
           $sum_txt.=" $indir/$a1/msmc.$chr.txt";
           my $pop1_sample=$pop_sam{$pop1};
           my $pop2_sample=$pop_sam{$pop2};
           my $sum_mask_bed="";
           my $temp_file="";
           if($pop_size==1){
               #it infer population history from 8000 to 30,000 years ago with 4 haplotype analysis;25G
               $sum_mask_bed="--mask $pop_mask{$pop1}/$pop1_sample/$pop1_sample.$chr.mask.bed --mask $pop_mask{$pop2}/$pop2_sample/$pop2_sample.$chr.mask.bed $pop_vcf{$pop1}/$pop1_sample/$pop1_sample.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sample/$pop2_sample.$chr.recode.vcf ";
#               $temp_file="$pop_mask{$pop1}/$pop1_sample/$pop1_sample.$chr.mask.bed $pop_mask{$pop2}/$pop2_sample/$pop2_sample.$chr.mask.bed $pop_vcf{$pop1}/$pop1_sample/$pop1_sample.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sample/$pop2_sample.$chr.recode.vcf";# easy to remove
           }
           elsif($pop_size==2){
               #it infer population history from 2000 to 50,000 years ago with 8 haplotype analysis;90G
               my ($pop1_sam1,$pop1_sam2)=(split(/\:/,$pop1_sample))[0,1];
               my ($pop2_sam1,$pop2_sam2)=(split(/\:/,$pop2_sample))[0,1];
               $sum_mask_bed="--mask $pop_mask{$pop1}/$pop1_sam1/$pop1_sam1.$chr.mask.bed --mask $pop_mask{$pop1}/$pop1_sam2/$pop1_sam2.$chr.mask.bed --mask $pop_mask{$pop2}/$pop2_sam1/$pop2_sam1.$chr.mask.bed --mask $pop_mask{$pop2}/$pop2_sam2/$pop2_sam2.$chr.mask.bed $pop_vcf{$pop1}/$pop1_sam1/$pop1_sam1.$chr.recode.vcf $pop_vcf{$pop1}/$pop1_sam2/$pop1_sam2.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sam1/$pop2_sam1.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sam2/$pop2_sam2.$chr.recode.vcf";
#               $temp_file="$pop_mask{$pop1}/$pop1_sam1/$pop1_sam1.$chr.mask.bed $pop_mask{$pop1}/$pop1_sam2/$pop1_sam2.$chr.mask.bed  $pop_mask{$pop2}/$pop2_sam1/$pop2_sam1.$chr.mask.bed $pop_mask{$pop2}/$pop2_sam2/$pop2_sam2.$chr.mask.bed $pop_vcf{$pop1}/$pop1_sam1/$pop1_sam1.$chr.recode.vcf $pop_vcf{$pop1}/$pop1_sam2/$pop1_sam2.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sam1/$pop2_sam1.$chr.recode.vcf $pop_vcf{$pop2}/$pop2_sam2/$pop2_sam2.$chr.recode.vcf";# easy to remove
           }
           else{
               die "warning: the haplotypes estimating Coalescence_rate of MSMC should not be more than 8 haplotype\n";
           }
           print S1 "cd $indir/$a1;export LD_LIBRARY_PATH=/opt/blc/python-3.1.2/lib:\$LD_LIBRARY_PATH;/opt/blc/python-3.1.2/bin/python3.1 /ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/history/MSMC/msmc-master/tools/generate_multihetsep.py $sum_mask_bed > msmc.$chr.txt \n";
       }
       #==========run rate===============
       if($pop_size==1){
           print S2 "cd $indir;/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/history/MSMC/msmc-master/build/msmc -R --skipAmbiguous -P '0,0,1,1' -o $a1.outfile -i 50 -t 10 -p '15*1+15*2' $sum_txt\n";
       }
       elsif($pop_size==2){
           print S2 "cd $indir;/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/history/MSMC/msmc-master/build/msmc -R --skipAmbiguous -P '0,0,0,0,1,1,1,1' -o $a1.outfile -i 50 -t 10 -p '15*1+15*2' $sum_txt\n";
       }
       else{
           die "warning: the haplotypes estimating Coalescence_rate of MSMC should not be more than 8 haplotype\n";
       }
   }
}

close S2;
close S1;
close IN;   
-
