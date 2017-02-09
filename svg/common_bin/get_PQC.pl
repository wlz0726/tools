#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename qw(basename dirname);

my %opt = (AT=>2, PT=>"BAC-denovo", outdir=>"./QA");
GetOptions(\%opt,"outdir:s","inPQCxlsx:s","PT:s","AT:i","organism:s","org_all:s","ctg:s","scaf:s","cov:s","snpf:s","indelf:s");
@ARGV || die"Name: get_PQC.pl
Description: script to get PQC table for BAC-denovo or BAC-WGRS
Usate: perl get_PQC.pl <IQC.xls> [--options]
    IQC.xls name format eg: IQC_BAC-denovo_HK12117_PSExyeD_MR_liangshuqing_20130402.xls
    --outdir <str>      output file directory, output file name is similar to IQC.xls file name [./QA]
    --inPQCxlsx <str>   set the xlsx file path used to copy it to the same dir of output file
    --PT <str>          project type, e.g:BAC-denovo,BAC-WGRS, default=BAC-denovo
    --AT <num>          Denovo assembly type:(default=2)
                            for BAC-denovo: 1.Survey, 2.Fine genome map,
                            3.Fine genome map(upgrade), 4.Complete map
    --organism <str>    organism list file, default no
    --org_all <str>     organism of all sample, if no --organism
    --ctg <str>         contig stat file, default no
    --scaf <str>        scaffold stat file, default no
    --cov <str>         coverage stat file, assembly coverage for BAC-denovo, reference coverage for BAC-WGRS, default no
    --snpf <str>        set snp result file for BAC-WGRS, default no
    --indelf <str>      set indel result file for BAC-WGRS, default no
Example:
    perl get_PQC.pl 01.Cleandata/List/IQC_*.xls --outdir ./QC --inPQCxlsx Assembly/Assembly_V2.4/lib/Report2/PQC/PQC_Bacteria-Denovo*.xlsx --PT BAC-denovo --AT 2 --organism 02.Assembly/stat/max_tax_organism --ctg 02.Assembly/stat/contig_stat.ncbi.tab --scaf 02.Assembly/stat/scaff_stat.ncbi.tab --cov 02.Assembly/stat/all_coverage.stat.xls
    perl get_PQC.pl 01.Cleandata/List/IQC_*.xls --outdir ./QC --inPQCxlsx Assembly/Assembly_V2.4/lib/Report2/PQC/PQC_Bacteria-WGRS*.xlsx --PT BAC-WGRS --organism 02.Assembly/stat/max_tax_organism --ctg 02.Assembly/stat/contig_stat.ncbi.tab --scaf 02.Assembly/stat/scaff_stat.ncbi.tab --cov 05.Comparative_Genomics/all_Coverage_stat.xls --snpf 05.Comparative_Genomics/all_SNP_stat.xls --indelf 05.Comparative_Genomics/all_InDel_stat.xls
\n";
#=============================================================================================

my $IQC_file = shift;
(-s $IQC_file) || die"error: can't find able file: $IQC_file, $!";
mkdir "$opt{outdir}" unless (-d "$opt{outdir}");

$opt{inPQCxlsx} && ($opt{inPQCxlsx} =~ s/\(/\\\(/, $opt{inPQCxlsx} =~ s/\)/\\\)/);

my (%scafh, %contigh, %coverh, %organismh, %lane_libh, %snph, %indelh, %reads_size);

my $b_iqc = basename ($IQC_file);
$opt{PT} ||= (split/_/,$b_iqc)[1] || "BAC-denovo";

$b_iqc =~ s/^IQC_/IQC_$opt{PT}_/;
my $b_pqc = $b_iqc;
my $date = &date;
$b_pqc =~ s/^IQC/PQC/;
$b_pqc =~ s/_\d+.xls/_$date.xls/;
my %hash =
("BAC-denovo"=>"Bacteria-Denovo(Hiseq2000)",
    "BAC-WGRS"=>"Bacteria-WGRS",
);
$b_pqc =~ s/$opt{PT}/$hash{$opt{PT}}/;
my $outfile = "$opt{outdir}/$b_pqc";

#--- get statistic of all samples
$opt{ctg} && &ass_stat($opt{ctg},\%contigh);
$opt{scaf} && &ass_stat($opt{scaf},\%scafh);
$opt{organism} && &organism($opt{organism},\%organismh);
lane_lib($IQC_file,\%lane_libh,\%organismh,$opt{org_all}, \%reads_size);
#$opt{cov} && ($opt{PT} eq "BAC-denovo") ? &cover_stat($opt{cov},\%coverh) : &cover_stat($opt{cov},\%coverh,1);
if ($opt{PT} =~ /denovo/) {
	$opt{cov} && &cover_stat($opt{cov},\%coverh);
	%reads_size && &depth_stat(\%reads_size,\%coverh,\%scafh);
}
if($opt{PT} =~ /WGRS/){
	$opt{cov} && &cover_stat($opt{cov},\%coverh,1);
    $opt{snpf} && &count($opt{snpf},\%snph);
    $opt{indelf} && &count($opt{indelf},\%indelh);
}
#--- end of get statistic

open PQC,">$outfile" || die$!;
#--- print head to out file
my $head = "SubProjectname\tSample_Name\tSpecies\tDate_MachineNO_FC_Lane_Library\t";
my $GS_head = "Ass_Type\tGenome size\t";
my $ass_head = "Total Num (#)\tTotal Length (bp)\tN50 (bp)\tN90 (bp)\tMax Length (bp)\t".
            "Min Length (bp)\tSequence GC (%)\t";
my $ref_head = "Reference size (bp)\tCovered Length (bp)\tCoverage (%)\tAverage depth(X)\t";
my $end = "Coverage(%)\tDepth(X)\tJudgement\n";
my $ref_end = "The number of SNPs\tThe number of InDels\tJudgement\n";
my (@sign,@N50,@Depth,@Cover);
if($opt{PT} eq "BAC-denovo"){
    print PQC $head,$GS_head,$ass_head,$ass_head,$end;
    @sign = ('Survey','Fine genome map','Fine genome map(upgrade)','Complete map','Others');
    ($opt{AT} =~ /\b[1234]\b/) || ($opt{AT} = 5);
}else{ #($opt{PT} eq "BAC-WGRS")
    print PQC $head,$ref_head,$ass_head,$ass_head,$ref_end;
}
#--- print every sample's statistic
foreach my $samp (sort keys %lane_libh){
    my $proj_spe = shift @{$lane_libh{$samp}};
    my $unok = 0;
    my @out;
    my $note;
    if($opt{PT} =~ /denovo/ && !$scafh{$samp}){
        $unok = 1;
        push @out,('--','--');
        @{$scafh{$samp}} = ('--') x 7;
        @{$contigh{$samp}} = ('--') x 7;
    }elsif($opt{PT} eq "BAC-denovo"){
        my ($gs_mask,$num_lim) = &BAC_GS(@{$scafh{$samp}}[1,-1], $opt{AT});
		if($opt{AT} == 1){ #-- survey
			$unok += compare($coverh{$samp}->[-1],100,1,'Depth',\$note,1,'X');
		}elsif($opt{AT} == 2){ #-- fine map
            $unok += compare($scafh{$samp}->[0],$num_lim,0,'#scaf',\$note,1);
			$unok += compare($coverh{$samp}->[-1],150,1,'Depth',\$note,1,'X');
        }elsif($opt{AT} == 3){ #-- fine map upgrade
            $unok += compare($contigh{$samp}->[0],$num_lim,0,'#contig',\$note,1);
			$unok += compare($coverh{$samp}->[-1],20,1,'Depth',\$note,1,'X');
        }elsif($opt{AT} == 4){ #-- complete map
			$unok += compare($coverh{$samp}->[-1],200,1,'Depth',\$note,1,'X');
		}
        if($opt{AT} == 2 || $opt{AT} == 3){ #-- fine map or fine map upgrade
            $unok += compare($coverh{$samp}->[-2],95,1,'Coverage',\$note,1,'%');
        }
		push @out,($sign[$opt{AT}-1],$gs_mask);
    }elsif($opt{PT} =~ /WGRS/){
		(defined $coverh{$samp}) ? (push @out,@{$coverh{$samp}}) : (push @out, ("--", "--", "--", "--"));
		if (!$scafh{$samp}) {
			@{$scafh{$samp}} = ('--') x 7;
			@{$contigh{$samp}} = ('--') x 7;
		}
    }

    push @out,@{$scafh{$samp}},@{$contigh{$samp}};
    if($opt{PT} =~ /denovo/){
		(defined $coverh{$samp}) ? (push @out,@{$coverh{$samp}}) : (push @out, ("--", "--"));
    }elsif($opt{PT} =~ /WGRS/){
        push @out,($snph{$samp}||'--', $indelh{$samp}||'--');
    }
    comma_add(@out);
    my $judge = $unok ? "N" : "Y";
    push @out,$judge;
    $note && (push @out,$note);
    print PQC join("\t",$proj_spe,@out),"\n";
    for(@{$lane_libh{$samp}}){
        print PQC " \t \t \t",$_,"\n";
    }
}
close PQC;

#--- copy xlsx file
$outfile =~ s/\(/\\\(/; $outfile =~ s/\)/\\\)/;
$opt{inPQCxlsx} && system ("cp $opt{inPQCxlsx} ${outfile}x");

#=============================================================================================
sub BAC_GS{
    my ($size, $gc, $At) = @_;
    $size || return('--','--');
    $size =~ s/,//g;
    $gc =~ s/\%$//;
    my $M = 5*10**6;
    my $M2 = 10**7;
    my ($sm,$s) = ($size < $M) ? ("GS<5M",0) :
        ($size < $M2) ? ("5M<GS<10M",1) : ("GS>10M",2);
    my ($gm,$g) = ($gc < 35 || $gc > 65) ? ("(Abnormal)",1) : ("(Normal)",0);
	#my @num = qw(100 150 0 200 300 0);
    my @num_scaf = qw(45 45 45 45 45 45); #-- fine map
	my @num_ctg = qw(100 150 0 200 300 0); #-- fine map upgrade
    return($sm.$gm, $num_scaf[3*$g+$s]) if ($At == 2);
    return($sm.$gm, $num_ctg[3*$g+$s]) if ($At == 3);
	return($sm.$gm, 0);
}
sub lane_lib{
    my ($IQC_file,$hash,$organismh,$organism, $reads_size) = @_;
    for(`less $IQC_file`){
        /\S/ || last;
        /^SubProjectname\s+/ && next;
        my @l = (split)[0,2,2,3,16];
        if(!$hash->{$l[1]}){
            $l[2] = $organismh->{$l[1]} || $organism || 'Unkmow';
            $l[3] = join("\t",@l);
        }
        push @{$hash->{$l[1]}},$l[3];
		$l[4] =~ s/,//g;
		$reads_size->{$l[1]} += $l[4];
    }
}
sub ass_stat{
    my ($stat,$hash) = @_;
    ($stat && -s $stat) || return(0);
    my $ok = 0;
    for(`less $stat`){
        if(/^Sample_name\s+/){
            $ok++;
            next;
        }
        ($ok == 2) || next;
        my @l = split;
        my $samp = shift @l;
        $hash->{$samp} = [@l];
    }
}
sub depth_stat{ #coverage depth
	my ($reads_size, $hash, $scafh) = @_; #&cover_stat1(\%reads_size,\%coverh,\%scafh);
	foreach my $name (keys %{$reads_size}) {
		if (exists $scafh->{$name}) {
			my $length = $scafh{$name}->[1]; $length =~ s/,//g;
			my $depth = $reads_size->{$name} / $length;
			$depth =~ s/(\.\d{2})\d*/$1/;
			push @{$hash->{$name}}, $depth;
		}
	}

}
sub cover_stat{
    my ($cover,$hash,$ref) = @_;
    ($cover && -s $cover) || return(0);
    for(`less $cover`){
        /^Sample_name\s+/ && next;
        /^\s*$/ && next;
		my @l = split;
		#$hash->{$l[0]} = $ref ? [@l[-4,-3,-2,-1]] : [@l[-2,-1]];
        $hash->{$l[0]} = $ref ? [@l[-4,-3,-2,-1]] : [$l[-2]];
    }
}
sub organism{
    my ($max_org,$hash) = @_;
    ($max_org && -s $max_org) || return(0);
    for(`less $max_org`){
        chomp;
        my @l = split /\s+/,$_,3;
        $hash->{$l[0]} = $l[2];
    }
}
sub date{
    my @date = (localtime())[5,4,3];
    $date[0]+=1900;
    $date[1]++;
    for(@date[1,2]){(length == 1) && ($_ = "0$_");}
    join("",@date[0..2]);
}
sub compare{
    my ($que,$stand,$large,$mask,$note,$detail,$unit) = @_;
    $stand || return(0);
    for($que,$stand){s/,//g;}
    ($stand == $que) && return(0);
    my $f = ">";
    my $uok = ($que > $stand) ? 1 : 0;#less is ok
    $large && ($uok = 1 - $uok, $f="<");#large is ok
    if($uok){
        $unit && ($que .= $unit);
        $unit && ($stand .= $unit);
        if($detail){
            $$note .= "$mask($que)$f$stand; ";
        }else{
            $$note .= $mask;
        }
    }
    $uok;
}
sub count{
    my ($inf,$hash) = @_;
    ($inf && -s $inf) || return(0);
    for(`less $inf`){
        /^Sample_name/ && next;
        my @l = split;
        $hash->{$l[0]} = $l[1];
    }
}
sub comma_add{
    foreach(@_){
        $_ || next;
        /[^\.\d]/ && next;
        $_ = /(\d+)\.(\d+)/ ? comma($1) . '.' . comma($2,1) : comma($_);
    }
}
sub comma{
    my ($c,$rev) = @_;
    (length($c) > 3) || return($c);
    $rev || ($c = reverse $c);
    $c =~ s/(...)/$1,/g;
    $rev || ($c = reverse $c);
    $c =~ s/^,//;
    $c;
}

__END__
