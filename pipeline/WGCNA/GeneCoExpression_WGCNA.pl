#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Path;
use File::Basename;
use Cwd;
use FindBin qw($Bin);
use lib "$Bin/lib";
use AnaMethod;

#读入参数并处理
my ($conf,$explist,$gene2symbol,$outdir, $mv_result_dir, $monitorOption,$help);

GetOptions(
        "conf=s" => \$conf,
        "list=s" => \$explist,
	"gene2symbol:s" => \$gene2symbol,
        "outdir:s" => \$outdir,
        "move:s" => \$mv_result_dir,
        "m:s" => \$monitorOption,
        "help|?" => \$help
);

&usage() if (!defined $conf || !defined $explist || $help);
$outdir = File::Spec->rel2abs($outdir);
$explist = File::Spec->rel2abs($explist);
$gene2symbol = File::Spec->rel2abs($gene2symbol) if($gene2symbol);

my $analysis_name = "GeneCoExpression_WGCNA";
my $shell = "$outdir/shell";
my $list = "$outdir/list"; mkpath $list;
my $process = "$outdir/process/$analysis_name";mkpath $process;
my $dependence = "$list/${analysis_name}_dependence.txt";

my ($IDcolumn, $Exprcolumn, $geneFrac, $weight,$res,$monitor) = &readConf($conf);
my ($sample_info) = &readList($explist);
my %sample_info = %$sample_info;
my @dep;

my $sample_shell_dir = "$shell/$analysis_name";
mkpath $sample_shell_dir;
foreach my  $sample1(sort keys %sample_info){
         my $dep_shell = $sample_info{$sample1};
         if($dep_shell ne "NA"){
             push @dep, "$dep_shell\t$sample_shell_dir/GeneCoExpression_WGCNA.sh:$res";
           }else{
             push @dep, "$sample_shell_dir/GeneCoExpression_WGCNA.sh:$res";
           }
        }
#shell
my $content = "$Bin/bin/getExpMatrix.pl -list $explist -IDcolumn $IDcolumn -Exprcolumn $Exprcolumn -geneFrac $geneFrac";
$content .= " -gene2symbol $gene2symbol" if($gene2symbol);
$content .= " -outdir $process && \\\n";
$content .= "$Bin/bin/WGCNA.pl -expMatrix $process/geneExpMatrix.xls -weight $weight -outdir $process";
$content .= "cp $Bin/bin/Cytoscape* -outdir $process";
if(defined $mv_result_dir){
                mkpath $mv_result_dir;
                $mv_result_dir = File::Spec->rel2abs($mv_result_dir);
                $content .= " && \\\nmv $process/Cytoscape* $process/Modules* $mv_result_dir";
        }
       
        AnaMethod::generateShell("$sample_shell_dir/GeneCoExpression_WGCNA.sh", $content);



#dependence
open DEP,">$dependence" or die "Cannot open file $dependence:$!\n";
my %count;
my @uniq_dep = grep { ++$count{ $_ } < 2; } @dep;
for (@uniq_dep) { print DEP "$_\n"; }

#生成qsub.sh
if(defined $monitor && defined $monitorOption){
        `echo "$monitor $monitorOption -i $dependence" >$list/${analysis_name}_qsub.sh`;
}


#===================== SUB Fuctions ====================

#读取输入的表达量文件列表
sub readList
{
        my ($file) = @_;
        my %hash;
        open IN,$file or die "Cannot open file $file:$!\n";
        while (<IN>) {
		chomp;
                next if(/^\s*$/ || /^\s*\#/);
                my @line = split(/\s+/);
		if($line[2]){
                	my $dependence_shell = $line[2];
	                $hash{$line[0]}=$dependence_shell;
		}else{
			$hash{$line[0]} = "NA";
		}
        }
        return (\%hash);
}

#读取输入的配置文件
sub readConf
{
        my ($file) = @_;
        my ($GeneColumn,$ExpressionColumn,$geneFrac, $weight,$res, $monitor);
        open IN, $file or die "Cannot open file $file:$!\n";
        while (<IN>){
                chomp;
                next if(/^\s*$/ || /^\s*\#/);
                $_ =~ s/^\s*//;
                $_ =~ s/\s*$//;
                if (/^(\w+)\s*=\s*(.*)$/xms) {
                        next if ($2 =~ /^\s*$/);
                        my $key = $1;
                        my $value = $2;
                        $value =~ s/\s*$//;
                        if ($key eq "GeneColumn") { $GeneColumn = $value;}
                        elsif ($key eq "ExpressionColumn") { $ExpressionColumn = $value; }
			elsif ($key eq "GeneFracThreshold") { $geneFrac = $value; }
			elsif ($key eq "WeightThreshold") { $weight = $value; }
        	        elsif ($key eq "qsubMemory") { $res = $value; }
                        elsif ($key eq "pymonitor") { $monitor = $value; }
                }
    }
        $GeneColumn ||= "1";
        $ExpressionColumn ||= "5";
        $res ||= "0.1G";
        $monitor ||= "/ifs4/BC_CANCER/02usr/chenly/pipeline/module/monitor";
        return ( $GeneColumn, $ExpressionColumn, $geneFrac,$weight, $res, $monitor);
}

sub usage
{
  die "Despcription: Module of Gene co-expression network analysis using WGCNA method
Date: 2016-3-29
Contact: linruichai\@genomics.cn
Usage:
\tperl $0 [options]
Options:
	-conf		<str>*	config file
	-list		<str>*	list file,format:sample geneExp_file shell_info(optional)
	-gene2symbol	<str>	gene id and gene symbol mapping file(optional), format:geneID symbol
	-outdir		<str>	output dir, default: ./
	-move		<str>	if this parameter is set,the final result will be moved to it from output dir
	-m		<str>	monitor options. will create monitor shell while defined this option
	-help|?		print help information

e.g.:
	perl $0 -conf GeneCoExpression_WGCNA.conf -list GeneExp.list -outdir outdir -move outdir/result/ -m 'taskmonitor -q bc.q -P rdtest -p WGCNA'
";
}
