#!/usr/bin/perl -w
use strict;
use Getopt::Long;

#read option
my ($outdir,$explist,$IDcolumn,$Exprcolumn,$gene2symbol,$geneFrac);
GetOptions(
	"list=s"=>\$explist,
	"outdir=s"=>\$outdir,
	"IDcolumn=i"=>\$IDcolumn,
	"Exprcolumn=i"=>\$Exprcolumn,
	"gene2symbol:s"=>\$gene2symbol,
	"geneFrac:f"=>\$geneFrac
);

die "
Description:
    Get gene expression matrix for WGCNA module.
Usage:
	*-list		<file>	list file of gene expression module,format:sample expression_file sh_info(optional)
	*-IDcolumn	<int>	column number of gene id in expression file
	*-Exprcolumn	<int>	column number of expression value in expression file
	 -geneFrac	<float> gene fraction ratio threshold, only genes that express in more than <float> samples are remained, default:0.5
	 -gene2symbol	<file>	gene id and gene symbol mapping file, format:geneID symbol, optional
	 -outdir	<file>	default: current dir
e.g.
    perl $0 -list geneExp.list -IDcolumn 1 -Exprcolumn 5 -gene2symbol gene2symbol.txt -outdir ./
" unless ($explist and $IDcolumn and $Exprcolumn);

$geneFrac ||= 0.5;

#store gene2symbol info
my %gene2symbol = ();
if($gene2symbol){
	open SYMBOL,"$gene2symbol";
	while(<SYMBOL>){
		chomp;
		my @a = split;
		$gene2symbol{$a[0]} = $a[1];
	}
	close SYMBOL;
}

#read directory
my (@xls,@Sname);
open IN,$explist or die "Cannot open my  file1 $explist:$!\n";
while (<IN>) {
      chomp;
      my @line_1 = split(/\s/);
      push(@Sname,$line_1[0]);
      push(@xls,$line_1[1]);
}
close IN;

my (%hash,%GeneID_all);
my @sample_name;
my $xls_vol = @xls - 1;
my $IDcol = $IDcolumn - 1;
my $Exprcol = $Exprcolumn -1;
my ($i,$sample);
for ($i=0;$i <= $xls_vol;$i++){
   $sample = $Sname[$i]; 
   push(@sample_name,$sample);
   open IN1,$xls[$i] or die "Can't open my file2 $xls[$i]:$!\n";
   while(<IN1>){
         chomp;
         my @line = split(/\t/,$_);
         my $GeneID = $line[$IDcol];
         if($line[$Exprcol] =~ /[a-zA-Z]/ ){
            my $name2 = $line[$Exprcol];
        }else{
             $hash{$GeneID}{$sample} = $line[$Exprcol];
             $GeneID_all{$GeneID} = $line[$Exprcol];
        }
   }
  close IN1;
}

open LIST,">$outdir/geneExpMatrix.xls";
print LIST "GeneID";
if($gene2symbol){
	print LIST "\tSymbol";
}
my $num;
for($num = 0;$num <= $xls_vol;$num++){
     print LIST "\t$sample_name[$num]";
}
print LIST "\n";

my $sample_n = scalar @sample_name;
my ($key1,$key2);
foreach $key1(sort keys %GeneID_all){
	my $n = 0;
	my $tmp = "";
	$tmp .= "$key1";
	if($gene2symbol){
		if(exists $gene2symbol{$key1}){
			$tmp .= "\t$gene2symbol{$key1}";
		}else{
			$tmp .= "\t-";
		}
	}
	foreach $key2(@sample_name){
		if (exists $hash{$key1}{$key2}){
			$tmp .= "\t$hash{$key1}{$key2}";
			$n++;
		}else{
			$tmp .= "\t0";			
		}
	}
	my $rate = $n/$sample_n;
	if($rate >= $geneFrac){
		print LIST "$tmp\n";
	}
}
