#! /usr/bin/perl

##This program was modified by liangshuqing at Wed Jan 30 13:45:38 CST 2013
##aim to set the precision of the statistics result
##after running this program, you can get the statistics information on the sreen and the files in separate folders.

=head1
	Usage:
		perl stat.pl [options] genome.seq

	Options:
		--prefix <str>                  set the keyname of result files, needed
		--stat <file>                   set the total stat output file name
		--gene <file>                   set gene cds file in fa format
		--repeat <str>                  stat repeat dir
			--trf <file>                set trf result in gff3 format
		--ncRNA <str>                   stat ncRNA dir
			--rRNA_denovo <file>        set denovo rRNA gff file
			--rRNA_homology <file>      set homology rRNA tab file
			--tRNA <file>               set tRNA gff3 file
			--sRNA <file>               set sRNA gff3 file
		--help                          get the help information

	Version: 2.0
	Contact: liangshuqing@bgitechsolutions.com 

=cut


use strict;
use warnings;

use Getopt::Long;
use File::Basename qw(basename dirname);
use FindBin qw($Bin);

my ($Stat,$Gene,$Repeat,$TRF);
my ($NcRNA,$TRNA,$RRNA_denovo,$RRNA_homology,$SRNA);
my ($Prefix,$Help);

GetOptions(
	"stat:s"=>\$Stat,
	"gene:s"=>\$Gene,
	"repeat:s"=>\$Repeat,
	"trf:s"=>\$TRF,
	"ncRNA:s"=>\$NcRNA,
	"tRNA:s"=>\$TRNA,
	"rRNA_denovo:s"=>\$RRNA_denovo,
	"rRNA_homology:s"=>\$RRNA_homology,
	"sRNA:s"=>\$SRNA,
	"prefix:s"=>\$Prefix,
	"help"=>\$Help
);

die `pod2text $0` if ($Help || @ARGV==0);

#==================Genome===============================
my (%seq);
my (%gene_num,%gene_len);
my (%TRF_num,%repeat_per);
my (%tRNA_num,%rRNA_num,%sRNA_num);
my ($seq_len, $Genome_gc, $Gene_num, $Gene_len, $Gene_avg_len, $pergenome, $Gene_gc, $Gene_inter_len, $Gene_inter_gc, $Gene_inter_len_per, $total_rRNAd_num, $total_rRNAh_num, $tRNA_sumnum, $sRNA_sumnum);

$seq_len=0;
##set the statistic precision
my $precision = '%.4f';

my $seq_file = shift;

open SEQ,$seq_file || die "$seq_file $!\n";

$/=">";
while(<SEQ>){
	chomp;
	next if ($_ eq "");
	my($name,$seq)=split(/\n/,$_,2);	
	$name=$1 if ($name=~/^(\S+)/);
	$seq=~s/[\n\r]+//g;
	$seq=uc($seq);
	$seq{$name}=length $seq;
	if (defined $Gene){$gene_num{$name}=0;}else{$gene_num{$name}="--";}
	if (defined $Gene){$gene_len{$name}=0;}else{$gene_len{$name}="--";}
	if (defined $TRF){$TRF_num{$name}=0;}else{$TRF_num{$name}="--";};
	if (defined $TRNA){$tRNA_num{$name}=0;}else{$tRNA_num{$name}="--";}
	if (defined $SRNA){$sRNA_num{$name}=0;}else{$sRNA_num{$name}="--";}
	$seq_len+=length $seq;
}
close SEQ;
$/="\n";

my$gstat=`$Bin/cs $seq_file`;
$Genome_gc=(split(/\n/,$gstat))[-1];
$Genome_gc=(split(/\t/,$Genome_gc))[-1];
$Genome_gc=~s/%//g;
$gstat=~s/\n\t/\n/g;

#===================Gene=============================
if(defined $Gene){
#if(defined $Gene && -d "$All/02.Gene-Prediction/"){
	my$dir=dirname($Gene);
	open OUT,">$dir/$Prefix.gene.stat" || die "$Prefix.gene.stat $!\n";
	open GENE,$Gene || die "$Gene $!\n";
	$Gene_gc=`$Bin/cs $Gene`;
	$Gene_gc=(split(/\n/,$Gene_gc))[-1];
	$Gene_gc=(split(/\t/,$Gene_gc))[-1];
	$Gene_gc=~s/%//g;
	$/=">";
	while(<GENE>){
		chomp;next if ($_ eq "");
		my($head,$seq)=split(/\n/,$_,2);
		my$gene_id=$1 if ($head=~/^(\S+)/);
		my$scaf=$1 if ($head =~ /locus=([\w\d]+)/);
		$seq=~s/[\n\r]+//g;
		$seq=uc($seq);
		$gene_num{$scaf}++;
		$gene_len{$scaf}+=(length $seq);
		$Gene_len += length $seq;
		$Gene_num++;
	}
	$Gene_avg_len = $Gene_len/$Gene_num;
	$pergenome = $Gene_len/$seq_len*100;
	close GENE;
	$Gene_inter_len=$seq_len-$Gene_len;
	$Gene_inter_len_per=$Gene_inter_len*100/$seq_len;
	$Gene_inter_gc=($Genome_gc*$seq_len-$Gene_gc*$Gene_len)/$Gene_inter_len;

	&comma_add (0, $Gene_num, $Gene_len, $Gene_avg_len, $Gene_inter_len);
	&comma_add (2, $Gene_gc, $pergenome, $Gene_inter_gc, $Gene_inter_len_per);
	print OUT "Gene Number:\t$Gene_num\n";
	print OUT "Gene Length:\t$Gene_len\n";
	print OUT "GC Content:\t$Gene_gc\n";
	print OUT "\% of Genome(Genes):\t$pergenome\n";
	print OUT "Gene Average Length:\t$Gene_avg_len\n";
	print OUT "Gene Internal Length:\t$Gene_inter_len\n";
	print OUT "Gene Internal GC Content:\t$Gene_inter_gc\n";
	print OUT "% of Genome(internal):\t$Gene_inter_len_per\n";
	close OUT;
	$/="\n";
}

#====================Repeat===========================
my ($TRF_number, $TRF_min, $TRF_max, $TRF_tlen, $TRF_pre);
my ($Min_number, $Min_min, $Min_max, $Min_tlen, $Min_pre);
my ($Mic_number, $Mic_min, $Mic_max, $Mic_tlen, $Mic_pre);
my ($Min_STD_min, $Min_STD_max, $Mic_STD_min, $Mic_STD_max);

if(defined $Repeat){
	if(defined $TRF){
		($TRF_number, $TRF_min, $TRF_max, $TRF_tlen, $TRF_pre) = (0, 1000, 0, 0, 0);
		($Min_number, $Min_min, $Min_max, $Min_tlen, $Min_pre) = (0, 1000, 0, 0, 0);
		($Mic_number, $Mic_min, $Mic_max, $Mic_tlen, $Mic_pre) = (0, 1000, 0, 0, 0);
		($Min_STD_min, $Min_STD_max, $Mic_STD_min, $Mic_STD_max) = (15, 65, 2, 10);
		my (%hash_TRF, %hash_Min, %hash_Mic);
		my $out_min_gff = $TRF; $out_min_gff =~ s/trf\.dat\.gff$/Minisatellite.DNA.dat.gff/;
		my $out_mic_gff = $TRF; $out_mic_gff =~ s/trf\.dat\.gff$/Microsatellite.DNA.dat.gff/;
		open MIN, ">$out_min_gff" || die "can not create file: $out_min_gff!\n";
		open MIC, ">$out_mic_gff" || die "can not create file: $out_mic_gff!\n";
		print MIN "##gff-version 3\n";
		print MIC "##gff-version 3\n";
		open TRF,$TRF || die "$TRF $!\n";
		while(my $line = <TRF>){
			chomp $line;
			next if ($line =~ /^#/);
			next if ($line !~ /PeriodSize=(\d+);/);
			my $cur_TRF_len = $1;
			my($scaf,$sta,$end, $copy)=(split(/\s+/, $line))[0,3,4,8];
			if ($sta > $end) { my $i = $sta; $sta = $end; $end = $i;}
			#--all
			$TRF_number ++;
			($cur_TRF_len < $TRF_min) && ($TRF_min = $cur_TRF_len);
			($cur_TRF_len > $TRF_max) && ($TRF_max = $cur_TRF_len);
			push @{$hash_TRF{$scaf}}, [$sta, $end];

			#--Minisatellite DNA
			if ($cur_TRF_len <= $Min_STD_max && $cur_TRF_len >= $Min_STD_min) {
				$Min_number ++;
				print MIN "$line\n";
				($cur_TRF_len < $Min_min) && ($Min_min = $cur_TRF_len);
				($cur_TRF_len > $Min_max) && ($Min_max = $cur_TRF_len);
				push @{$hash_Min{$scaf}}, [$sta, $end];
			}

			#--Microsatellite DNA
			if ($cur_TRF_len <= $Mic_STD_max && $cur_TRF_len >= $Mic_STD_min) {
				$Mic_number ++;
				print MIC "$line\n";
				($cur_TRF_len < $Mic_min) && ($Mic_min = $cur_TRF_len);
				($cur_TRF_len > $Mic_max) && ($Mic_max = $cur_TRF_len);
				push @{$hash_Mic{$scaf}}, [$sta, $end];
			}

			$copy=(split(/;/,$copy))[2];
			$copy=$1 if ($copy =~ /CopyNumber=(\S+)/);
			$TRF_num{$scaf}++;
		}
		close TRF;
		close MIC;
		close MIN;

		$TRF_min = $TRF_max if ($TRF_max == 0);
		$Min_min = $Min_max if ($Min_max == 0);
		$Mic_min = $Mic_max if ($Mic_max == 0);
		foreach my $chr (sort keys %hash_TRF) { $TRF_tlen += &Conjoin_fragment($hash_TRF{$chr});}
		foreach my $chr (sort keys %hash_Min) { $Min_tlen += &Conjoin_fragment($hash_Min{$chr});}
		foreach my $chr (sort keys %hash_Mic) { $Mic_tlen += &Conjoin_fragment($hash_Mic{$chr});}
		$TRF_pre = $TRF_tlen/$seq_len*100;
		$Min_pre = $Min_tlen/$seq_len*100;
		$Mic_pre = $Mic_tlen/$seq_len*100;

		&comma_add (0, $TRF_number, $TRF_min, $TRF_max, $TRF_tlen, $Min_number, $Min_min, $Min_max, $Min_tlen, $Mic_number, $Mic_min, $Mic_max, $Mic_tlen);
		&comma_add (4, $TRF_pre, $Min_pre, $Mic_pre);
		open TRF, ">$Repeat/$Prefix.TRF.stat" || die "can not create file: $Repeat/$Prefix.TRF.stat!\n";
		print TRF "Type\tNumber(#)\tRepeat Size(bp)\tTotal Length(bp)\tIn Genome(%)\n";
		print TRF "TRF\t$TRF_number\t$TRF_min-$TRF_max\t$TRF_tlen\t$TRF_pre\n";
		print TRF "Minisatellite DNA\t$Min_number\t$Min_min-$Min_max\t$Min_tlen\t$Min_pre\n";
		print TRF "Microsatellite DNA\t$Mic_number\t$Mic_min-$Mic_max\t$Mic_tlen\t$Mic_pre\n";
		close TRF;
	}
}

#===================ncRNA=============================
my($tRNA_len,$rRNA_len,$sRNA_len)=(0,0,0);
my($tRNA_per,$rRNA_per,$sRNA_per)=(0,0,0);
my($tRNA_avglen,$rRNA_avglen,$sRNA_avglen)=(0,0,0);

if(defined $NcRNA){
	($total_rRNAd_num, $total_rRNAh_num, $tRNA_sumnum, $sRNA_sumnum) = (0, 0, 0, 0);
	open OUT,">$NcRNA/$Prefix.ncRNA.stat" || die "$!\n";
	print OUT "\tType\tNumber#\tAvg_Len\tTotal_Len\t% in Genome\n";
	if(defined $TRNA){
		read_gff3($TRNA,\$tRNA_sumnum,\$tRNA_avglen,\$tRNA_len,\$tRNA_per,\%tRNA_num);
		&comma_add (0, $tRNA_sumnum, $tRNA_avglen, $tRNA_len);
		&comma_add (4, $tRNA_per);
		print OUT "\ttRNA\t$tRNA_sumnum\t$tRNA_avglen\t$tRNA_len\t$tRNA_per\n";
	}
	else { print OUT "\ttRNA\t-\t-\t-\t-\n"; }
	if(defined $RRNA_denovo){
		chomp (my @rRNAd_info = `perl $Bin/denovo_rRNA.pl $RRNA_denovo $seq_file`);
		$total_rRNAd_num = pop @rRNAd_info;
		&comma_add (0, $total_rRNAd_num);
		print OUT join ("\n", @rRNAd_info) . "\n";
	}
	else {
		print OUT "rRNA_de\t5S\t-\t-\t-\t\n";
		print OUT "\t16S\t-\t-\t-\t-\n";
		print OUT "\t23S\t-\t-\t-\t\n";
	}
	if(defined $RRNA_homology){
		chomp (my @rRNAh_info = `perl $Bin/homology_rRNA.pl --rRNA $RRNA_homology --sequence $seq_file`);
		$total_rRNAh_num = pop @rRNAh_info;
		&comma_add (0, $total_rRNAh_num);
		print OUT join ("\n", @rRNAh_info) . "\n";
	}
	else {
		print OUT "rRNA_ho\t5S\t-\t-\t-\t\n";
		print OUT "\t16S\t-\t-\t-\t-\n";
		print OUT "\t23S\t-\t-\t-\t\n";
	}
	if(defined $SRNA){
		read_gff3($SRNA,\$sRNA_sumnum,\$sRNA_avglen,\$sRNA_len,\$sRNA_per,\%sRNA_num);
		&comma_add (0, $sRNA_sumnum, $sRNA_avglen, $sRNA_len);
		&comma_add (4, $sRNA_per);
		print OUT "\tsRNA\t$sRNA_sumnum\t$sRNA_avglen\t$sRNA_len\t$sRNA_per\n";
	}
	else { print OUT "\tsRNA\t-\t-\t-\t-\n"; }
	close OUT;
}

#========================== stat all result ==========================#
if (defined $Stat) {
	open OUT, ">$Stat" || die;
	&comma_add(0,$seq_len) if (defined $seq_len);
	print OUT "Genome Size(bp):\t", ((defined $seq_len)?$seq_len:"-"), "\n";
	print OUT "GC Content(%):\t", ((defined $Genome_gc)?$Genome_gc:"-"), "\n";
	print OUT "Gene Number(#):\t", ((defined $Gene_num)?$Gene_num:"-"), "\n";
	print OUT "Gene Length(bp):\t", ((defined $Gene_len)?$Gene_len:"-"), "\n";
	print OUT "Gene Average Length(bp):\t", ((defined $Gene_avg_len)?$Gene_avg_len:"-"), "\n";
	print OUT "Gene Length/Genome(%):\t", ((defined $pergenome)?$pergenome:"-"), "\n";
	print OUT "GC Content in Gene Region(%):\t", ((defined $Gene_gc)?$Gene_gc:"-"), "\n";
	print OUT "Intergenic Region Length(bp):\t", ((defined $Gene_inter_len)?$Gene_inter_len:"-"), "\n";
	print OUT "GC Content in Intergenic Region(%):\t", ((defined $Gene_inter_gc)?$Gene_inter_gc:"-"), "\n";
	print OUT "Intergenic Region Length/Genome(%):\t", ((defined $Gene_inter_len_per)?$Gene_inter_len_per:"-"), "\n";
	print OUT "Tandem Repeat Number(#):\t", ((defined $TRF_number)?$TRF_number:"-"), "\n";
	print OUT "Tandem Repeat Length(bp):\t", ((defined $TRF_tlen)?$TRF_tlen:"-"), "\n";
	print OUT "Tandem Repeat Size(bp):\t", ((defined $TRF_min && defined $TRF_max)?"$TRF_min-$TRF_max":"-"), "\n";
	print OUT "Tandem Repeat Length/Genome(%):\t", ((defined $TRF_pre)?$TRF_pre:"-"), "\n";
	print OUT "Minisatellite DNA Number(#):\t", ((defined $Min_number)?$Min_number:"-"), "\n";
	print OUT "Microsatellite DNA Number(#):\t", ((defined $Mic_number)?$Mic_number:"-"), "\n";
	print OUT "rRNA Number(#):\t",((defined $total_rRNAd_num && $total_rRNAd_num ne "0")?$total_rRNAd_num:((defined $total_rRNAh_num)?$total_rRNAh_num:"-")),"\n";
	print OUT "tRNA Number(#):\t", ((defined $tRNA_sumnum)?$tRNA_sumnum:"-"), "\n";
	print OUT "sRNA Number(#):\t", ((defined $sRNA_sumnum)?$sRNA_sumnum:"-"), "\n";
	print OUT "Genomic Island Number(#):\t-\n";
	print OUT "Prophage Number(#):\t-\n";
	close OUT;
}


#==================sub program========================
sub read_gff3{
	my($gff3,$sum_num,$avg_len,$len,$percentage,$num)=@_;
	die "CHECK: $gff3 is not exists !" if (!-e $gff3);
	open GFF,$gff3 || die "$gff3 $!";
	while(<GFF>){
		next if (/^#/);
		my$scaf=(split)[0];
		$$sum_num++;
		$num->{$scaf}++;
	}
	$$len=`perl  $Bin/stat_TE.pl -gff $gff3 -rank all`;
	$$len=$1 if ($$len=~/(\d+)/);
	$$len=0 if ($$len eq "");
	if($$sum_num != 0){$$avg_len = sprintf("%d", $$len/$$sum_num);}else{$$avg_len=0;}
	$$percentage = $$len/$seq_len*100;
	close GFF;
}


sub Conjoin_fragment{
	my $pos_p = shift; ##point to the two dimension input array
	my $distance = shift || 0;
	my $new_p = [];         ##point to the two demension result array

	my ($all_size, $pure_size, $redunt_size) = (0,0,0);

	return (0,0,0) unless(@$pos_p);

	foreach my $p (@$pos_p) {
		($p->[0],$p->[1]) = ($p->[0] <= $p->[1]) ? ($p->[0],$p->[1]) : ($p->[1],$p->[0]);
		$all_size += abs($p->[0] - $p->[1]) + 1;
	}

	@$pos_p = sort {$a->[0] <=>$b->[0]} @$pos_p;
	push @$new_p, (shift @$pos_p);

	foreach my $p (@$pos_p) {
		if ( ($p->[0] - $new_p->[-1][1]) <= $distance ) { # conjoin two neigbor fragements when their distance lower than 10bp
			if ($new_p->[-1][1] < $p->[1]) { $new_p->[-1][1] = $p->[1];}

		}else{ push @$new_p, $p;} ## not conjoin
	}
	@$pos_p = @$new_p;

	foreach my $p (@$pos_p) { $pure_size += abs($p->[0] - $p->[1]) + 1;}

	$redunt_size = $all_size - $pure_size;
	return $pure_size;
}

sub comma_add {
	my $nu = shift;
	my $arg = "%.${nu}f";
	foreach (@_) {
		$_ = sprintf($arg,$_);
		$_ = /(\d+)\.(\d+)/ ? comma($1) . '.' . $2 : comma($_);
	}
}
sub comma{
	my ($c,$rev) = @_;
	(length($c) > 3) || return($c);
	$rev || ($c = reverse $c);
	$c =~ s/(...)/$1,/g;
	$rev || ($c = reverse $c);
	$rev ? ($c =~ s/,$//) : ($c =~ s/^,//);
	$c;
}

