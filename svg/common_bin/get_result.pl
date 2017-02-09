#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin $Script);
use Getopt::Long;
use File::Basename qw(basename dirname);

sub usage {
	print STDERR "
	perl get_result.pl [options] <workdir> <sample name list file>
	option:
	--type <str>      set which analysis to save.
	                  can be \"data-assembly-gene-repeat-ncRNA-GIs-prophage-function\
					         -SNP-InDel-synteny-CorePan-phylogenetic-family\". default no.
	--seqlist <file>  set the sequence list of samples for getting the statistics table if no \"--type assembly\".
	                  format should be:
	                    sample_name sample_sequence_path
	--config <file>   input config file which discribes comparative genomics analysis 
	                  (SNP-InDel-synteny-CorePan-phylogenetic-family).
	                  Format is same as BAC_pipeline.pl's config file.
	--outdir <str>    set the output directory. [<workdir>/Result/]
	--log <file>      save log info to this file\n\n";
	exit;
}

my ($Type, $Seqlist, $Config, $Resultdir, $Log);
GetOptions("type:s" => \$Type, "seqlist:s" => \$Seqlist, "config:s" => \$Config, "outdir:s" => \$Resultdir, "log:s" => \$Log);

(@ARGV == 2) || &usage; 

my ($Workdir, $sample_list) = @ARGV;
my (@sample, %sample_seq, $sample_name);
$Log && open LOG, ">$Log";

my ($ori, $out);
my $PGAP_stat = "$Bin/stat/PGAP.stat.pl";
$Resultdir ||= "$Workdir/Result";
$Type ||= "";
$Type =~ s/-/ /g;
$Type = " $Type ";
$Seqlist ||= "";
$Config ||= "";

my (%HASH_SNP, %HASH_InDel, %HASH_CorePan, %HASH_synteny, %HASH_family, %HASH_PhyTree);
$Config && &parser_config ($Config, \%HASH_SNP, \%HASH_InDel, \%HASH_CorePan, \%HASH_synteny, \%HASH_family, \%HASH_PhyTree);

&make_directory ($Resultdir);

chomp (@sample = `less $sample_list`);
@sample = grep (/^\s*\S+/, @sample);

if ($Seqlist) {
	foreach (`less $Seqlist`) {
		chomp;
		my ($name, $path) = split;
		$sample_seq{$name}{ass_path} = $path;
	}
}

if ($Type =~ / data| assembly| gene| repeat| ncRNA| GIs| prophage| function/) {
	&make_directory ("$Resultdir/Separate");
}

if ($Type =~ / data/ && -d "$Workdir/01.Cleandata") {
	#--- get clean argument
	my @clean_arg_list;
	&get_arg_clean ("$Workdir/Shell/Step0_cleandata.sh", \@clean_arg_list);

	foreach my $temp_name (@sample) {
		$sample_name = $temp_name;
		&make_directory ("$Resultdir/Separate/$sample_name");
		if (-d "$Workdir/01.Cleandata/$sample_name") {
			&make_directory ("$Resultdir/Separate/$sample_name/1.Cleandata");

			#--- save clean reads
			chomp (my $reads = `ls $Workdir/01.Cleandata/$sample_name/*.fq.*gz`);
			my @reads = split (/\s+/, $reads);
			foreach my $read (@reads) {
				my ($ins,$lib,$num,$tar)=($1,$2,$3,$4)if($read=~/$sample_name\.L(\d+)_(.*)_(\d?)\.fq\.clean((\.gz)*)$/);
				($ins && $num) || next;
				@{$sample_seq{$sample_name}{ins}{$ins}} = @clean_arg_list;
				&copy_file($read,"$Resultdir/Separate/$sample_name/1.Cleandata/$sample_name.L${ins}_${lib}_Clean.$num.fq$tar");
				#B212.L2000_ENDrsjDAADWAAPEI-41_Clean.1.fq.gz
				#B212.L2000_ENDrsjDAADWAAPEI-41_2.fq.clean.gz
			}

			#--- save pictures
			chomp (my $pngs = `ls $Workdir/01.Cleandata/$sample_name/*.png`);
			my @pngs = split (/\s+/, $pngs);
			foreach my $png (@pngs) {
				my ($ins, $lib, $flag, $type) = ($1,$2,$3,$4) if ($png =~ /$sample_name\.(\d+)\.(.*)\.(\w+)\.(\w+)\.png/);
				($ins && $flag && $type) || next;
				my $new_name = "$sample_name.${ins}_$lib";
				$new_name .= ($flag eq "raw") ? "_Raw" : (($flag eq "clean") ? "_Clean" : "");
				$new_name .= ($type eq "base") ? ".base" : (($type eq "qual") ? ".qual" : "");
				$new_name .= ".png";
				&copy_file ($png, "$Resultdir/Separate/$sample_name/1.Cleandata/$new_name");
			}
			#B212.2000_ENDrsjDAADWAAPEI-41_Clean.base.png
			#B212.2000_ENDrsjDAADWAAPEI-41_Clean.qual.png
			#B212.2000_ENDrsjDAADWAAPEI-41_Raw.base.png
			#B212.2000_ENDrsjDAADWAAPEI-41_Raw.qual.png
			#B212.2000.ENDrsjDAADWAAPEI-41.clean.qual.png
			#B212.2000.ENDrsjDAADWAAPEI-41.raw.base.png

			#--- get reads stat
			my %stat;
			chomp (my $logs = `ls $Workdir/01.Cleandata/$sample_name/*.readfq.log`);
			my @logs = split (/\s+/, $logs);
			my $real_ins_file = "$Workdir/01.Cleandata/List/clean_stat.xls";
			my %real_ins;
			open IN, $real_ins_file || print STDERR "can not read the actual insert size!\n";
			while (<IN>) {
				chomp;
				next if (/Sample_Name/);
				my ($cur_lib, $cur_ins) = (split (/\s+/, $_))[1,2];
				$cur_ins =~ s/,//;
				$real_ins{$cur_lib} = $cur_ins;
			}
			close IN;

			foreach my $log (@logs) {
				my ($ins, $lib) = ($1, $2) if ($log =~ /$sample_name\.(\d+)\.(\S+)\.readfq.log$/);
				($ins && $lib) || next;
				my ($old_ins, $new_ins);
				$old_ins = $ins;
				$ins = (exists $real_ins{$lib}) ? $real_ins{$lib} : $ins;
				$new_ins = $ins;
				open IN, $log || die;
				while (<IN>) {
					chomp;
					next if (/^\s*$/ || /^#/ || /total_size/);
					if (/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\(\S+:\S+\))\s+(\d+)\s+(\d+)/) {
						my ($Reads_Len, $Raw_Data, $Adapter, $Duplication, $Total_Reads, $Clean_Data, $LowQual_Filtered) = ($8, $1, $5, $6, $2, $9, $3);
						my $Filtered_Reads;
						$Adapter = ($Adapter * 100) / $Raw_Data;
						$Duplication = ($Duplication * 100) / $Raw_Data;
						$Filtered_Reads = (($Raw_Data - $Clean_Data) * 100) / $Raw_Data;
						$LowQual_Filtered = ($LowQual_Filtered * 100) / $Raw_Data;
						$Raw_Data = $Raw_Data/1000000;
						$Clean_Data = $Clean_Data/1000000;

						&comma_add (0, $ins, $Raw_Data, $Total_Reads, $Clean_Data);
						&comma_add (2, $Adapter, $Duplication, $LowQual_Filtered, $Filtered_Reads);
						#--save
						$stat{$new_ins} = join ("\t", ($sample_name, $ins, $Reads_Len, $Raw_Data, $Adapter, $Duplication, $Total_Reads, $Filtered_Reads, $LowQual_Filtered, $Clean_Data));

						#--correct cut argument
						if ($Reads_Len =~ /(\d+):(\d+)/) {
							my ($temp_1, $temp_2) = ($1, $2);
							my @temp_arr = @{$sample_seq{$sample_name}{ins}{$old_ins}};
							if ($temp_arr[0] eq "*"||$temp_arr[1] eq "*"){($temp_arr[0], $temp_arr[1]) = (1, $temp_1);}
							elsif (($temp_arr[1]-$temp_arr[0]+1)>$temp_1) {$temp_arr[1] = $temp_1 + $temp_arr[0] - 1;}
							if ($temp_arr[2] eq "*"||$temp_arr[3] eq "*"){($temp_arr[2], $temp_arr[3]) = (1, $temp_2);}
							elsif (($temp_arr[3]-$temp_arr[2]+1)>$temp_2) {$temp_arr[3] = $temp_2 + $temp_arr[2] - 1;}
							$sample_seq{$sample_name}{ins}{$old_ins} = \@temp_arr;
						}
#						last;
# total_size total_reads low_quality  N-num_size  is_adapter duplication        poly read_length output_size single_size
#   52367040      581856     1221660       23670           0           0         180     (90:90)    50000040     1121490
					}
				}#end of while
				close IN;
			}#end of foreach
			open OUT, ">$Resultdir/Separate/$sample_name/1.Cleandata/${sample_name}_Cleandata.stat" || die;
			print OUT "Sample Name\tInsert Size(bp)\tReads Length(bp)\tRaw Data(Mb)\tAdapter(%)\tDuplication(%)\tTotal Reads\tFiltered Reads(%)\tLow Quality Filtered Reads(%)\tClean Data(Mb)\n";
			#B212    500     (90:90) 106     0.05    0.11    500     4.80    2.38    101,000,160
			foreach (sort {$a <=> $b} keys %stat) {print OUT $stat{$_}, "\n";}
			close OUT;
			#-- end of get reads stat
		}
	}
}


if ($Type =~ / assembly/ && -d "$Workdir/02.Assembly") {
	my %hash_sample;
	#--get fna file list
	open IN, "$Workdir/02.Assembly/stat/reach_stand.list" || die;
	while (<IN>) {chomp; if (/^(\S+)\s+(\S+)/) { $hash_sample{$1}{fna} = $2; } }
	close IN;

	foreach my $temp_name (@sample) {
		$sample_name = $temp_name;
		&make_directory ("$Resultdir/Separate/$sample_name");
		if (-d "$Workdir/02.Assembly/$sample_name") {
			&make_directory ("$Resultdir/Separate/$sample_name/2.Assembly");
			($ori, $out) = ("$Workdir/02.Assembly/$sample_name", "$Resultdir/Separate/$sample_name/2.Assembly");
			my $sample_fna = $hash_sample{$sample_name}{fna};
			my $sample_agp = $sample_fna; $sample_agp =~ s/fna$/agp/; 
			my $sample_ctg = $sample_fna; $sample_ctg =~ s/fna$/scaftig/;

			&copy_file ($sample_fna, "$out/$sample_name.seq");	
			&copy_file ($sample_agp, "$out/$sample_name.agp");	
			&copy_file ($sample_ctg, "$out/$sample_name.contig");

			my $stat = dirname ($sample_fna) . "/ass_stat.tab.ncbi";
			`tail -n 8 $stat | sed "s/^\t//" > $out/$sample_name.assembly.stat`;

			&copy_file ("$ori/../stat/kmer_fig/$sample_name.png", "$out/$sample_name.kmer.png");
			&copy_file ("$ori/kmer/KmerStat.tab", "$out/$sample_name.kmer.stat");
			&copy_file ("$ori/../stat/gcdep_fig/$sample_name.GC_depth.png", "$out/$sample_name.GC-depth.png");

			$sample_seq{$sample_name}{ass_path} = $sample_fna;
			#02.Assembly/stat/kmer_fig/B212.png
		}
	}

	#--get kmer number of assembly
	my $parameter_file = "$Workdir/02.Assembly/stat/parameter.log";
	if (! -e $parameter_file) {
		warn "There is not assembly parameter file: $parameter_file!\n";
	}
	else {
		open IN, $parameter_file || die "can not open file: $parameter_file!\n";
		while (<IN>) {
			chomp;
			if (/^\s*(\S+)\s*\|\s*.*-K\s+(\d+)\s*/) { 
				foreach my $sample_name (@sample) {
					if ($1 eq $sample_name) {
						$sample_seq{$1}{kmer} = $2;
						last;
					}
				}
			}
		}
		close IN;
		#B212 | all -K 33 | krskgf ; gapclose -t 8;
		#NCPPB3335 | all -L 65 -R -u -d 1 -F -K 47 | krskgf ; gapclose -t 8;
	}
	#--end of get kmer number
}

if ($Type =~ / gene| repeat| ncRNA| GIs| prophage/ && -d "$Workdir/03.Genome_Component") {
	foreach my $temp_name (@sample) {
		$sample_name = $temp_name;
		&make_directory ("$Resultdir/Separate/$sample_name");
		if (-d "$Workdir/03.Genome_Component/$sample_name") {
			&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component");
			my $stat_arg = "";
			if ($Type =~ / gene/ && -d "$Workdir/03.Genome_Component/$sample_name/01.Gene-Prediction") {
				&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component/Gene_Prediction");
				($ori, $out) = ("$Workdir/03.Genome_Component/$sample_name/01.Gene-Prediction", "$Resultdir/Separate/$sample_name/3.Genome_Component/Gene_Prediction");
				chomp (my $cds = `ls $ori/*.cds`);
				chomp (my $pep = `ls $ori/*.pep`);
				chomp (my $gff = `ls $ori/*.gff`);
				chomp (my $png = `ls $ori/*.cds.png`);
				my $out_cds = "$out/$sample_name.$1" if ($cds =~ /^.*\/[^\/]*\.([^\.\/]+\.cds)$/);
				my $out_pep = "$out/$sample_name.$1" if ($pep =~ /^.*\/[^\/]*\.([^\.\/]+\.pep)$/);
				my $out_gff = "$out/$sample_name.$1" if ($gff =~ /^.*\/[^\/]*\.([^\.\/]+\.gff)$/);
				my $out_png = "$out/$sample_name.$1" if ($png =~ /^.*\/[^\/]*\.([^\.\/]+\.cds.png)$/);

				&copy_file ($cds, $out_cds);
				&copy_file ($pep, $out_pep);
				&copy_file ($gff, $out_gff);
				&copy_file ($png, $out_png);
				#all.scafSeq.fna.glimmer.cds

				(-e $out_cds) && ($stat_arg .= " --gene $out_cds");
			}

			if ($Type =~ / repeat/ && -d "$Workdir/03.Genome_Component/$sample_name/02.Repeat-finding") {
				&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component/Tandem_Repeat");
				($ori, $out) = ("$Workdir/03.Genome_Component/$sample_name/02.Repeat-finding", "$Resultdir/Separate/$sample_name/3.Genome_Component/Tandem_Repeat");
				&copy_file ("$ori/*.trf/*.trf.dat", "$out/$sample_name.trf.dat");
				&copy_file ("$ori/*.trf/*.trf.dat.gff", "$out/$sample_name.trf.dat.gff");

				(-e "$out/$sample_name.trf.dat.gff") && ($stat_arg .= " --repeat $out --trf $out/$sample_name.trf.dat.gff");
			}

			if ($Type =~ / ncRNA/ && -d "$Workdir/03.Genome_Component/$sample_name/03.ncRNA-finding") {
				&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component/ncRNA_Finding");
				($ori, $out) = ("$Workdir/03.Genome_Component/$sample_name/03.ncRNA-finding", "$Resultdir/Separate/$sample_name/3.Genome_Component/ncRNA_Finding");
				$stat_arg .= " --ncRNA $out";
				if (-d "$ori/tRNA") {
					&copy_file ("$ori/tRNA/*.tRNA", "$out/$sample_name.tRNA");
					&copy_file ("$ori/tRNA/*.tRNA.gff", "$out/$sample_name.tRNA.gff");
					&copy_file ("$ori/tRNA/*.tRNA.structure", "$out/$sample_name.tRNA.structure");

					(-e "$out/$sample_name.tRNA.gff") && ($stat_arg .= " --tRNA $out/$sample_name.tRNA.gff");
				}
				if (-d "$ori/rRNA/Denovo") {
					&copy_file ("$ori/rRNA/Denovo/*.rRNA.fa", "$out/$sample_name.denovo.rRNA.fa");
					&copy_file ("$ori/rRNA/Denovo/*.rRNA.gff", "$out/$sample_name.denovo.rRNA.gff");

					(-e "$out/$sample_name.denovo.rRNA.gff") && ($stat_arg .= " --rRNA_denovo $out/$sample_name.denovo.rRNA.gff");
				}
				if (-d "$ori/rRNA/Homology") {
					&copy_file ("$ori/rRNA/Homology/*.rRNA.blast.tab", "$out/$sample_name.homology.rRNA.tab");
					&copy_file ("$ori/rRNA/Homology/*.rRNA.blast.tab.gff", "$out/$sample_name.homology.rRNA.gff");

					(-e "$out/$sample_name.homology.rRNA.tab") && ($stat_arg .= " --rRNA_homology $out/$sample_name.homology.rRNA.tab");
				}
				if (-d "$ori/sRNA") {
					&copy_file ("$ori/sRNA/*.sRNA.cmsearch.all.gff", "$out/$sample_name.sRNA.cmsearch.all.gff");
					&copy_file ("$ori/sRNA/*.sRNA.cmsearch.confident.gff", "$out/$sample_name.sRNA.cmsearch.confident.gff");
					&copy_file ("$ori/sRNA/*.sRNA.cmsearch.confident.nr.gff", "$out/$sample_name.sRNA.cmsearch.confident.nr.gff");

					(-e "$out/$sample_name.sRNA.cmsearch.confident.nr.gff") && ($stat_arg .= " --sRNA $out/$sample_name.sRNA.cmsearch.confident.nr.gff");
				}
			}

			if ($Type =~ / GIs/ && -d "$Workdir/03.Genome_Component/$sample_name/04.Gis") {
				&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component/Genomic_Island");
				($ori, $out) = ("$Workdir/03.Genome_Component/$sample_name/04.Gis", "$Resultdir/Separate/$sample_name/3.Genome_Component/Genomic_Island");
				&copy_file ("$ori/*.blat.xls", "$out/$sample_name.GIs.blat.xls");
				&copy_file ("$ori/*.filter.xls", "$out/$sample_name.GIs.blat.filter.xls");
			} 

			if ($Type =~ / prophage/ && -d "$Workdir/03.Genome_Component/$sample_name/05.Prophage") {
				&make_directory ("$Resultdir/Separate/$sample_name/3.Genome_Component/Prophage");
				($ori, $out) = ("$Workdir/03.Genome_Component/$sample_name/05.Prophage", "$Resultdir/Separate/$sample_name/3.Genome_Component/Prophage");
				&copy_file ("$ori/*.blat.xls", "$out/$sample_name.Prophage.blat.xls");
				&copy_file ("$ori/*.filter.xls", "$out/$sample_name.Prophage.blat.filter.xls");
			} 

			#create stat file
			if (-e $sample_seq{$sample_name}{ass_path}) {
				`perl $PGAP_stat $stat_arg --stat $Resultdir/Separate/$sample_name/3.Genome_Component/$sample_name.Genome_Component.stat --prefix $sample_name $sample_seq{$sample_name}{ass_path}`;
			}
			else {
				warn "Warning: there isn't $sample_name genomics seuqence file. can not calculate it! Please check if set --seqlist or not!\n";
			}

		}
	}
}

if ($Type =~ / function/ && -d "$Workdir/04.Genome_Function") {
	foreach my $temp_name (@sample) {
		$sample_name = $temp_name;
		&make_directory ("$Resultdir/Separate/$sample_name");
		if (-d "$Workdir/04.Genome_Function/$sample_name") {
			&make_directory ("$Resultdir/Separate/$sample_name/4.Genome_Function");
			if ($Type =~ / function/ && -d "$Workdir/04.Genome_Function/$sample_name/01.General_Gene_Annotation") {
				$ori = "$Workdir/04.Genome_Function/$sample_name/01.General_Gene_Annotation";
				$out = "$Resultdir/Separate/$sample_name/4.Genome_Function";
				my ($out_general, $out_pathogen) = ("$Resultdir/Separate/$sample_name/4.Genome_Function/General_Gene_Annotation", "$Resultdir/Separate/$sample_name/4.Genome_Function/Pathogen_Analysis");
				my $anno_flag = 0;
				if (-d "$ori/04.iprscan") {
					&make_directory ($out_general);
					&copy_file ("$ori/04.iprscan/*.iprscan", "$out_general/$sample_name.iprscan");
					&copy_file ("$ori/04.iprscan/*.iprscan.gene.GO", "$out_general/$sample_name.iprscan.gene.GO");
					&copy_file ("$ori/04.iprscan/*.iprscan.gene.wego", "$out_general/$sample_name.iprscan.gene.wego");
					&copy_file ("$ori/04.iprscan/*.iprscan.gene.ipr", "$out_general/$sample_name.iprscan.gene.ipr");
					&copy_file ("$ori/04.iprscan/*.go.png", "$out_general/$sample_name.go.png");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.kegg") {
					&make_directory ($out_general);
					&copy_file ("$ori/03.anno.kegg/kegg.list.filter", "$out_general/$sample_name.kegg.list.filter");
					&copy_file ("$ori/03.anno.kegg/kegg.list.filter.anno", "$out_general/$sample_name.kegg.list.anno");
					&copy_file ("$ori/03.anno.kegg/functional_classification_2.png", "$out_general/$sample_name.kegg.functional_classification_2.png");
					&copy_file ("$ori/03.anno.kegg/kegg.list.catalog.map.gene.new", "$out_general/$sample_name.kegg.list.catalog.map.gene");
					&copy_directory ("$ori/03.anno.kegg/kegg.list.catalog.map.fig", "$out_general/KEGG_MAP");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.nr") {
					&make_directory ($out_general);
					&copy_file ("$ori/03.anno.nr/nr.list.filter", "$out_general/$sample_name.nr.list.filter");
					&copy_file ("$ori/03.anno.nr/nr.list.filter.anno", "$out_general/$sample_name.nr.list.anno");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.swissprot") {
					&make_directory ($out_general);
					&copy_file ("$ori/03.anno.swissprot/swissprot.list.filter", "$out_general/$sample_name.swissprot.list.filter");
					&copy_file ("$ori/03.anno.swissprot/swissprot.list.filter.anno", "$out_general/$sample_name.swissprot.list.anno");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.trembl") {
					&make_directory ($out_general);
					&copy_file ("$ori/03.anno.trembl/trembl.list.filter", "$out_general/$sample_name.trembl.list.filter");
					&copy_file ("$ori/03.anno.trembl/trembl.list.filter.anno", "$out_general/$sample_name.trembl.list.anno");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.cog") {
					&make_directory ($out_general);
					&copy_file ("$ori/03.anno.cog/cog.list.filter", "$out_general/$sample_name.cog.list.filter");
					&copy_file ("$ori/03.anno.cog/cog.list.filter.anno", "$out_general/$sample_name.cog.list.anno");
					&copy_file ("$ori/03.anno.cog/cog.list.class.catalog", "$out_general/$sample_name.cog.list.class.catalog");
					&copy_file ("$ori/03.anno.cog/cog.list.cogclass.png", "$out_general/$sample_name.cog.list.cogclass.png");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.phi") {
					&make_directory ($out_pathogen);
					&copy_file ("$ori/03.anno.phi/phi.list.filter", "$out_pathogen/$sample_name.phi.list.filter");
					&copy_file ("$ori/03.anno.phi/phi.list.filter.anno", "$out_pathogen/$sample_name.phi.list.anno");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.cazy") {
					&make_directory ($out_pathogen); &make_directory ("$out_pathogen/Plant");
					&copy_file ("$ori/03.anno.cazy/cazy.list.filter", "$out_pathogen/Plant/$sample_name.cazy.list.filter");
					&copy_file ("$ori/03.anno.cazy/cazy.list.filter.anno", "$out_pathogen/Plant/$sample_name.cazy.list.anno");
					&copy_file ("$ori/03.anno.cazy/cazy.list.catalog", "$out_pathogen/Plant/$sample_name.cazy.list.catalog");
					&copy_file ("$ori/03.anno.cazy/statis_5class.stat", "$out_pathogen/Plant/$sample_name.cazy.5class.stat");
					&copy_file ("$ori/03.anno.cazy/statis_allclass.stat", "$out_pathogen/Plant/$sample_name.cazy.allclass.stat");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.vfdb") {
					&make_directory ($out_pathogen); &make_directory ("$out_pathogen/Animal");
					&copy_file ("$ori/03.anno.vfdb/vfdb.list.filter", "$out_pathogen/Animal/$sample_name.vfdb.list.filter");
					&copy_file ("$ori/03.anno.vfdb/vfdb.list.filter.anno", "$out_pathogen/Animal/$sample_name.vfdb.list.anno");
					$anno_flag = 1;
				}
				if (-d "$ori/03.anno.ardb") {
					&make_directory ($out_pathogen); &make_directory ("$out_pathogen/Animal");
					&copy_file ("$ori/03.anno.ardb/ardb.list.filter", "$out_pathogen/Animal/$sample_name.ardb.list.filter");
					&copy_file ("$ori/03.anno.ardb/ardb.list.filter.anno", "$out_pathogen/Animal/$sample_name.ardb.list.anno");
					&copy_file ("$ori/03.anno.ardb/ardb.list.filter.anno.all", "$out_pathogen/Animal/$sample_name.ardb.list.anno.all");
					$anno_flag = 1;
				}
				if (-d "$ori/05.T3SS") {
					&make_directory ($out_pathogen);
					&copy_file ("$ori/05.T3SS/*.effectiveT3.out", "$out_pathogen/$sample_name.effectiveT3.xls");
					&copy_file ("$ori/05.T3SS/*.effectiveT3.out.stat", "$out_pathogen/$sample_name.effectiveT3.stat");
					$anno_flag = 1;
				}
				&copy_file ("$ori/anno.table", "$out/$sample_name.annotation.table") if ($anno_flag == 1);
			}
		}
	}
}

if ($Type =~ / SNP| InDel| synteny| CorePan| phylogenetic| family/ && -d "$Workdir/05.Comparative_Genomics") {
	&make_directory ("$Resultdir/Combination");
}
if ($Type =~ / SNP| InDel/ && -d "$Workdir/05.Comparative_Genomics/Coverage") {
	&make_directory ("$Resultdir/Combination/Coverage");
	$ori = "$Workdir/05.Comparative_Genomics/Coverage";
	$out = "$Resultdir/Combination/Coverage";
	chomp ( my @xls_files = `ls $ori/*/all_coverage.stat.xls`);
	my $coverage_strings;
	foreach my $xls_file (@xls_files) {
		open IN, $xls_file || die;
		while (<IN>) {
			chomp;
			next if (/^\s*$/);
			my @w = split;
			next if (@w < 6);
		    &comma_add (0, @w[2,3,5]);
			$coverage_strings .= join ("\t", @w) . "\n";
		}
		close IN;
	}
	$coverage_strings =~ s/\n$//;
	my %counts;
	$coverage_strings = join "\n", grep {++$counts{$_} < 2} map { $_->[2]} sort {$a->[0] cmp $b->[0] || $a->[1] cmp $b->[1]} map {[(split)[0,1], $_]} (split /\n/, $coverage_strings);
	open OUT, ">$out/all_coverage.stat.xls" || die "can not create file: $out/all_coverage.stat.xls!\n";
	print OUT "$coverage_strings\n";
	close OUT;
}
if ($Type =~ / SNP/ && -d "$Workdir/05.Comparative_Genomics/SNP") {
	&make_directory ("$Resultdir/Combination/SNP");
	foreach my $key (sort keys %HASH_SNP) { # id_num, array
		my @array = @{$HASH_SNP{$key}};
		my $ref_name = shift @array;

		$ori = "$Workdir/05.Comparative_Genomics/SNP/$key\_$ref_name";
		if (! -d $ori) {
			warn "ERROR: number $key of SNP, no analysis directory! Skip it!\n"; next;
		}
		$out = "$Resultdir/Combination/SNP/SNP_$key\_$ref_name";
		&make_directory ($out);
		#-- start to copy file
		&copy_file ("$ori/clean.snp.pileup2.anno", "$out/$key\_$ref_name.snp");
		&copy_file ("$ori/clean.snp.pileup2.stat", "$out/$key\_$ref_name.gene_snp.stat");
		open OUT, ">$out/SNP_$key\_$ref_name.readme" || die;
		print OUT "reference:\t$ref_name\nquery:\t", join ("\t", @array), "\n";
		close OUT;
		&make_directory ("$out/Anno");
		&copy_file ("$ori/Anno/merge/*.total.cds.stat", "$out/$key\_$ref_name.total.cds.stat");
		foreach my $query_name (@array) {
			if (-d "$ori/Anno/$query_name") {
				&copy_directory ("$ori/Anno/$query_name", "$out/Anno/$query_name");
			}
			else { warn "ERROR: number $key of SNP, no annotation result of $query_name!\n"; next;}
		}

	}
}#-- end of SNP
if ($Type =~ / InDel/ && -d "$Workdir/05.Comparative_Genomics/InDel") {
	&make_directory ("$Resultdir/Combination/InDel");
	foreach my $key (sort keys %HASH_InDel) {
		my @array = @{$HASH_InDel{$key}};
		my $ref_name = shift @array;

		$ori = "$Workdir/05.Comparative_Genomics/InDel/$key\_$ref_name";
		if (! -d $ori) {
			warn "ERROR: number $key of InDel, no analysis directory! Skip it!\n"; next;
		}
		$out = "$Resultdir/Combination/InDel/InDel_$key\_$ref_name";
		&make_directory ($out);
		&make_directory ("$out/Anno");
		open OUT, ">$out/InDel_$key\_$ref_name.readme" || die;
		print OUT "reference:\t$ref_name\nquery:\t", join ("\t", @array), "\n";
		close OUT;
		foreach my $query_name (@array) {
			&copy_file ("$ori/Result/$query_name.InDel", "$out/$key\_$ref_name\_$query_name.InDel");
			if (-d "$ori/Anno/$query_name") {
				&copy_directory ("$ori/Anno/$query_name", "$out/Anno/$query_name");
			}
			else { warn "ERROR: number $key of InDel, no annotation result of $query_name!\n"; next;}
		}
		&copy_file ("$ori/Anno/*_InDel_mutation.stat.xls", "$out/$key\_$ref_name\_InDel_mutation.stat.xls");
		&copy_file ("$ori/Anno/*_InDel_type.stat.xls", "$out/$key\_$ref_name\_InDel_type.stat.xls");
		&copy_file ("$ori/Anno/*_InDel_length.dis", "$out/$key\_$ref_name\_InDel_number.xls");
		&copy_file ("$ori/Anno/*_InDel_length.dis.png", "$out/$key\_$ref_name\_InDel_number.png") if (@array > 1);

	}
}#-- end of InDel
if ($Type =~ / synteny/ && -d "$Workdir/05.Comparative_Genomics/Synteny") {
	&make_directory ("$Resultdir/Combination/Synteny");
	foreach my $key (sort keys %HASH_synteny) {
		my @array = @{$HASH_synteny{$key}};
		my $synteny_type = shift @array;
		next if (! $synteny_type =~ /^nt[12]$|^aa[12]$/);
		if ($synteny_type eq "nt1") {
			next if (@array < 2);
			my ($ref_name, $query_name) = @array[0, 1];
			$ori = "$Workdir/05.Comparative_Genomics/Synteny/$key\_nt1_$ref_name";
			$out = "$Resultdir/Combination/Synteny/Synteny_nt_$key\_$ref_name";
			&make_directory ($out);
			&copy_file ("$ori/figure/$ref_name-$query_name.nuc.parallel.png", "$out/$ref_name\_$query_name.nucleic_acid.png");
			&copy_file ("$ori/synteny/a-b.blastn.m8", "$out/$ref_name\_$query_name.m8.xls");
		}#-- end of nt1
		elsif ($synteny_type eq "nt2") {
			next if (@array < 3);
			my ($ref1_name, $ref2_name, $query_name) = @array[0, 1, 2];
			$ori = "$Workdir/05.Comparative_Genomics/Synteny/$key\_nt2_$ref1_name\_$ref2_name";
			$out = "$Resultdir/Combination/Synteny/Synteny_nt_$key\_$ref1_name\_$ref2_name";
			&make_directory ($out);
			&copy_file ("$ori/figure/$query_name-$ref1_name-$ref2_name.nuc.parallel.png", "$out/$ref1_name\_$ref2_name\_$query_name.nucleic_acid.png");
			&copy_file ("$ori/synteny/a-b.blastn.m8", "$out/$ref1_name\_$query_name.m8.xls");
			&copy_file ("$ori/synteny/a-c.blastn.m8", "$out/$ref2_name\_$query_name.m8.xls");
		}#-- end of nt2
		if ($synteny_type eq "aa1") {
			next if (@array < 2);
			my ($ref_name, $query_name) = @array[0, 1];
			$ori = "$Workdir/05.Comparative_Genomics/Synteny/$key\_aa1_$ref_name";
			$out = "$Resultdir/Combination/Synteny/Synteny_aa_$key\_$ref_name";
			&make_directory ($out);
			&copy_file ("$ori/figure/$ref_name-$query_name.pep.parallel.png", "$out/$ref_name\_$query_name.amino_acid.png");
			&copy_file ("$ori/synteny/a-b.best.hit", "$out/$ref_name\_$query_name.synteny.list.xls");
			&copy_file ("$ori/synteny/a-b.best_stat", "$out/$ref_name\_$query_name.stat");
		}#-- end of aa1
		elsif ($synteny_type eq "aa2") {
			next if (@array < 3);
			my ($ref1_name, $ref2_name, $query_name) = @array[0, 1, 2];
			$ori = "$Workdir/05.Comparative_Genomics/Synteny/$key\_aa2_$ref1_name\_$ref2_name";
			$out = "$Resultdir/Combination/Synteny/Synteny_aa_$key\_$ref1_name\_$ref2_name";
			&make_directory ($out);
			&copy_file ("$ori/figure/$query_name-$ref1_name-$ref2_name.pep.parallel.png", "$out/$ref1_name\_$ref2_name\_$query_name.amino_acid.png");
			&copy_file ("$ori/synteny/a-b.best.hit", "$out/$ref1_name\_$query_name.synteny.list.xls");
			&copy_file ("$ori/synteny/a-c.best.hit", "$out/$ref2_name\_$query_name.synteny.list.xls");
			&copy_file ("$ori/synteny/a-b.best_stat", "$out/$ref1_name\_$query_name.stat");
			&copy_file ("$ori/synteny/a-c.best_stat", "$out/$ref2_name\_$query_name.stat");
		}#-- end of nt2
	}
}#-- end of synteny
if ($Type =~ / CorePan/ && -d "$Workdir/05.Comparative_Genomics/Core_Pan") {
	&make_directory ("$Resultdir/Combination/Core-Pan");
	foreach my $key (sort keys %HASH_CorePan) {
		my @array = @{$HASH_CorePan{$key}};
		my $ref_name = shift @array;

		$ori = "$Workdir/05.Comparative_Genomics/Core_Pan/$key\_$ref_name";
		if (! -d $ori) {
			warn "ERROR: number $key of Core_Pan, no analysis directory! Skip it!\n"; next;
		}
		&copy_directory ("$ori/Result", "$Resultdir/Combination/Core-Pan/Core-Pan_$key\_$ref_name");
		open OUT, ">$Resultdir/Combination/Core-Pan/Core-Pan_$key\_$ref_name/Core-Pan_$key\_$ref_name.readme" || die;
		print OUT "reference:\t$ref_name\nquery:\t", join ("\t", @array), "\n";
		close OUT;
	}
}#-- end of CorePan
if ($Type =~ / family/ && -d "$Workdir/05.Comparative_Genomics/Gene_Family") {
	&make_directory ("$Resultdir/Combination/Gene_Family");
	foreach my $key (sort keys %HASH_family) {
		my @array = @{$HASH_family{$key}};

		$ori = "$Workdir/05.Comparative_Genomics/Gene_Family/$key\_Gene_Family";
		if (! -d $ori) {
			warn "ERROR: number $key of Gene_Family, no analysis directory! Skip it!\n"; next;
		}
		$out = "$Resultdir/Combination/Gene_Family/Gene_Family_$key";
		&make_directory ($out);
		open OUT, ">$out/Gene_Family_$key.readme" || die;
		print OUT "strand:\t", join ("\t", @array), "\n";
		close OUT;
		&copy_file ("$ori/Output/*.hcluster.stat", "$out/GeneFamily.stat");
		&copy_file ("$ori/GeneFamily.xls", "$out/GeneFamily.xls");
		&copy_file ("$ori/Output/*.hcluster.stat.single-copy", "$out/GeneFamily.single-copy.stat");
		&copy_file ("$ori/GeneFamily.single-copy.xls", "$out/GeneFamily.single-copy.xls");
		&copy_directory ("$ori/Output/gene_families", "$out/gene_families");
		&copy_directory ("$ori/Output/distance_data", "$out/distance_data");
	}
}#-- end of family
if ($Type =~ / phylogenetic/ && -d "$Workdir/05.Comparative_Genomics/Phylogenetic_Tree") {
	&make_directory ("$Resultdir/Combination/Phylogenetic_Tree");
	foreach my $key (sort keys %HASH_PhyTree) {
		my @array = @{$HASH_PhyTree{$key}};
		my $P_Type = shift @array;

		if ((uc $P_Type) eq "SNP") {
			foreach my $type_num (@array) {
				$ori = "$Workdir/05.Comparative_Genomics/Phylogenetic_Tree/SNP/SNP_$type_num";
				if (! -d $ori) {
					warn "ERROR: number $key of Phylogenetic_Tree, SNP $type_num no analysis directory! Skip it!\n";
					next;
				}
				my @query_list;
				&get_ref_query ("$Resultdir/Combination/SNP/SNP_$type_num\_*/SNP_$type_num\_*.readme", \@query_list);
				my $ref_name = shift @query_list;
				$out = "$Resultdir/Combination/Phylogenetic_Tree/SNP_$type_num\_$ref_name";
				&make_directory ($out);
				&copy_file ("$Resultdir/Combination/SNP/SNP_$type_num\_*/SNP_$type_num\_*.readme", "$out/SNP_$type_num\_$ref_name.readme");
				&copy_file ("$ori/*.newick", "$out/SNP_$type_num\_$ref_name.tree");
				&copy_file ("$ori/*.tree.png", "$out/SNP_$type_num\_$ref_name.tree.png");
				&copy_file ("$ori/*_snp_num.png", "$out/SNP_$type_num\_$ref_name.SNP_num.png");
				&copy_file ("$ori/KaKs/*.KaKs.png", "$out/SNP_$type_num\_$ref_name.KaKs.png");
			}
		}#-- end of SNP of Phylogenetic_Tree
		if ((uc $P_Type) eq "CORE-PAN") {
			foreach my $type_num (@array) {
				$ori = "$Workdir/05.Comparative_Genomics/Phylogenetic_Tree/Core_Pan/Core_Pan_$type_num";
				if (! -d $ori) {
					warn "ERROR: number $key of Phylogenetic_Tree, Core_Pan $type_num no analysis directory! Skip it!\n";
					next;
				}
				my @query_list;
				&get_ref_query ("$Resultdir/Combination/Core-Pan/Core-Pan_$type_num\_*/Core-Pan_$type_num\_*.readme", \@query_list);
				my $ref_name = shift @query_list;
				$out = "$Resultdir/Combination/Phylogenetic_Tree/Core-Pan_$type_num\_$ref_name";
				&make_directory ($out);
				&copy_file ("$Resultdir/Combination/Core-Pan/Core-Pan_$type_num\_*/Core-Pan_$type_num\_*.readme", "$out/Core-Pan_$type_num\_$ref_name.readme");
				&copy_file ("$ori/*.newick", "$out/Core-Pan_$type_num\_$ref_name.tree");
				&copy_file ("$ori/*.tree.png", "$out/Core-Pan_$type_num\_$ref_name.tree.png");
			}
		}#-- end of CORE-PAN of Phylogenetic_Tree
		if ((uc $P_Type) eq "GENE-FAMILY") {
			foreach my $type_num (@array) {
				$ori = "$Workdir/05.Comparative_Genomics/Phylogenetic_Tree/Gene_Family/Gene_Family_$type_num";
				if (! -d $ori) {
					warn "ERROR: number $key of Phylogenetic_Tree, Gene Family $type_num no analysis directory! Skip it!\n";
					next;
				}
				my @query_list;
				&get_ref_query ("$Resultdir/Combination/Gene_Family/Gene_Family_$type_num/Gene_Family_$type_num.readme", \@query_list);
				$out = "$Resultdir/Combination/Phylogenetic_Tree/Gene_Family_$type_num";
				&make_directory ($out);
				&copy_file ("$Resultdir/Combination/Gene_Family/Gene_Family_$type_num/Gene_Family_$type_num.readme", "$out/Gene_Family_$type_num.readme");
				&copy_file ("$ori/*.newick", "$out/Gene_Family_$type_num.tree");
				&copy_file ("$ori/*.tree.png", "$out/Gene_Family_$type_num.tree.png");
			}
		}#-- end of GENE-FAMILY of Phylogenetic_Tree
	}
}#-- end of Phylogenetic Tree


if (($Type =~ / data/ && -d "$Workdir/01.Cleandata") || ($Type =~ / assembly/ && -d "$Workdir/02.Assembly")) {
	open OUT, ">$Resultdir/Separate/Clean_Assembly_arg.list" || die "can not create file: $Resultdir/Separate/Clean_Assembly_arg.list!\n";
	foreach my $cur_sample_name (sort keys %sample_seq) {
		print OUT "Sample:\t$cur_sample_name\n";
		if (exists $sample_seq{$cur_sample_name}{ins}) {

#----------------- don't merge lib which have the same arguments ----------			
			foreach my $cur_ins (sort {$a<=>$b} keys %{$sample_seq{$cur_sample_name}{ins}}) {
				my $arugments = join ("\t", @{$sample_seq{$cur_sample_name}{ins}{$cur_ins}});
				&comma_add (0, $cur_ins);
				print OUT "Insert Size:\t$cur_ins\t$arugments\n";
			}

#----------------- merge lib which have the same arguments ----------------
#			my %ins_arg;
#			map {my @cur_arr=@{$sample_seq{$cur_sample_name}{ins}{$_}}; 
#				my $l=join(" ",@cur_arr); 
#				$ins_arg{$l} .= "$_ ";} 
#			keys %{$sample_seq{$cur_sample_name}{ins}};
#
#			foreach my $cur_keys (sort keys %ins_arg) {
#				my @stat_ins = $ins_arg{$cur_keys} =~ /(\d+)/g;
#				@stat_ins = sort {$a<=>$b} @stat_ins;
#				my @cur_arr=@{$sample_seq{$cur_sample_name}{ins}{$stat_ins[0]}};
#				&comma_add (0, @stat_ins);
#
#				print OUT "Insert Size:\t", join("\t",@stat_ins), "\n";
#				print OUT "Cut Read:\t$cur_arr[0]\t$cur_arr[1]\t$cur_arr[2]\t$cur_arr[3]\n";
#				print OUT "Quality:\t$cur_arr[4]\t$cur_arr[5]\t$cur_arr[6]\n";
#				print OUT "N:\t$cur_arr[7]\n";
#				print OUT "Adapter:\t$cur_arr[8]\n";
#				print OUT "Duplication:\t$cur_arr[9]\n";
#			}
#------------------------- end of merge ----------------------------------
		}
		if (exists $sample_seq{$cur_sample_name}{kmer}) {
			print OUT "Assembly kmer:\t$sample_seq{$cur_sample_name}{kmer}\n";
		}
		print OUT "\n";
	}
	close OUT;
}

close LOG;

################################# sub function ####################################

sub get_arg_clean {
	my ($clean_sh, $out) = @_;
	if (! -e $clean_sh) {
		warn "There is not clean shell file: $clean_sh!\n";
	}
	else {
		my ($cut1_start, $cut1_end, $cut2_start, $cut2_end, $q_qual, $q_num, $n_num, $adp_num, $adp_mismatch, $dup);
		my $pre;
		open IN, "$clean_sh" || die "can not open file $clean_sh!\n";
		while (<IN>) {
			chomp;
			next if (!/Clean_Data\.pl/);
			($cut1_start, $cut1_end) = ($1, $2) if (/--c_set1\s+(\d+),(\d+)/);
			($cut2_start, $cut2_end) = ($1, $2) if (/--c_set2\s+(\d+),(\d+)/);
			($q_qual, $q_num) = ($1, $2) if (/--q_set\s+(\d+),(\d+)/);
			$n_num = $1 if (/--n_set\s+(\d+)/);
			$adp_num = $1 if (/--readfq='.*-l\s+(\d+)/);
			$adp_mismatch= $1 if (/--readfq='.*-m\s+(\d+)/);
			$dup = (/--readfq='.*-d'/ || /--readfq='.*-d\s+/) ? 1 : 0;
		}
#--c_set1 1,90 --c_set2 1,90 --q_set 84,36 --n_set 9 --readfq='-l 15 -m 3 -d -z' --data_lim 100,50
		close IN;
		(defined $cut1_start) ? &comma_add (0, $cut1_start) : ($cut1_start = "*");
		(defined $cut1_end) ? &comma_add (0, $cut1_end) : ($cut1_end = "*");
		(defined $cut2_start) ? &comma_add (0, $cut2_start) : ($cut2_start = "*");
		(defined $cut2_end) ? &comma_add (0, $cut2_end) : ($cut2_end = "*");
		(defined $q_qual) ? &comma_add (0, $q_qual) : ($q_qual = 84);
		(defined $q_num) ? &comma_add (0, $q_num) : ($q_num = 36);
		(defined $n_num) ? &comma_add (0, $n_num) : ($n_num = 9);
		(defined $adp_num) ? &comma_add (0, $adp_num) : ($adp_num = 15);
		(defined $adp_mismatch) ? &comma_add (0, $adp_mismatch) : ($adp_mismatch = 3);
		(defined $dup) ? &comma_add (0, $dup) : ($dup = 1);
		$q_qual -= 64;
		($q_qual == 2) ? ($pre = 20) : ($pre = 40);

		@{$out} = ($cut1_start, $cut1_end, $cut2_start, $cut2_end, $q_qual, $pre, $q_num, $n_num, $adp_num, $dup);
	}
}


sub make_directory {
	mkdir "$_[0]", 0755 unless (-d "$_[0]");
	$Log && print LOG "mkdir $_[0]\n";
}

sub copy_directory {
	chomp (my $old = `ls $_[0]/*`);
	my $new = $_[1];
	$old = (split (/\n/, $old))[0];
	$old = $1 if ($old =~ /(^.*)\/[^\/\s]+$/);
	if (-d $old) {
		(-d $new) && `rm -r $new`;
		`cp -r $old $new`;
		`chmod -R 755 $new`;
		$Log && print LOG "cp -r $old $new\n";
	}
	else { warn "Warning: cp -r $_[0] to $_[1] error! There is not dir: $_[0]!\n";}
}

sub move_file {
	chomp (my $old = `ls $_[0]`);
	my $new = $_[1];
	if (-e $old) {
		(-e $new) && `rm $new`;
		`mv $old $new`;
		`chmod 755 $new`;
		$Log && print LOG "mv $old $new\n";
	}
	else { warn "Warning: mv $_[0] to $_[1] error! There is not $_[0]!\n";}
}

sub copy_file {
	chomp (my $old = `ls $_[0]`);
	my $new = $_[1];
	if (-e $old) {
		(-e $new) && `rm $new`;
		`cp $old $new`;
		`chmod 755 $new`;
		$Log && print LOG "cp $old $new\n";
	}
	else { warn "Warning: cp $_[0] to $_[1] error! There is not $_[0]!\n";}
}


sub comma_add {
	my $nu = shift;
	my $arg = "%.${nu}f";
	foreach (@_) {
		$_ = sprintf($arg,$_);
		$_ = /(\d+)\.(\d+)/ ? comma($1) . '.' . $2 : comma($_);
	}
	return 1;
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

sub parser_config {
	my ($Config, $HASH_SNP, $HASH_InDel, $HASH_CorePan, $HASH_synteny, $HASH_family, $HASH_PhyTree) = @_;
	my $flag = 0;
	open IN, $Config || die "can not open file: $Config!\n";
	while (<IN>) {
		chomp;
		next if (/^\s*$|^\s*#/);
		/\#/ && ($_ = substr ($_, 0, index($_, '#')));
		s/^\s+|\s+$//g;
		if (/^SNP:/) { $flag = 2; next;}
		if (/^INDEL:/) { $flag = 3; next;}
		if (/^CORE-PAN:/) { $flag = 4; next;}
		if (/^SYNTENY:/) { $flag = 5; next;}
		if (/^GENE-FAMILY:/) { $flag = 6; next;}
		if (/^PHYLOGENY:/) { $flag = 7; next;}
		if (/(\d+)\s*:\s*(\S+)\s+(.+)$/) {
			my @query_list = split (/\s+/, $3);
			if ($flag == 2) { push (@{$HASH_SNP->{$1}}, $2, @query_list); next;}
			if ($flag == 3) { push (@{$HASH_InDel->{$1}}, $2, @query_list); next;}
			if ($flag == 4) { push (@{$HASH_CorePan->{$1}}, $2, @query_list); next;}
			if ($flag == 5) { push (@{$HASH_synteny->{$1}}, $2, @query_list); next;}
			if ($flag == 6) { push (@{$HASH_family->{$1}}, $2, @query_list); next;}
			if ($flag == 7) { push (@{$HASH_PhyTree->{$1}}, $2, @query_list); next;}
		}
	}
	close IN;
}

sub get_ref_query {
	my ($in_file, $out_array) = @_;
	chomp ($in_file = `ls $in_file`);
	open IN, $in_file || return 0;
	while (<IN>) {
		chomp;
		next if (/^\s*$|^\s*#/);
		s/^\s+|\s+$//g;
		my @w = split;
		if ($w[0] =~ /^reference:$|^query:$|^strand:$/) { shift @w; push @{$out_array}, @w;}
		#reference:      Brucella
		#query:  S3
		#strand: S3      S6      S7      Brucella
	}
	close IN;
} 

__END__
