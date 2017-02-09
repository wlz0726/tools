#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ($PT, $AT, $Project, $TemplateR, $TemplateD, $RQC, $DQC, $Help) = ("BAC-denovo", 2, "Mgtest_xxx", "/nas/MG01/DOCUMENTS/QA/06.QAQC_updata/RQC", "/nas/MG01/DOCUMENTS/QA/06.QAQC_updata/DQC");
GetOptions ("PT:s"=>\$PT, "AT:n"=>\$AT, "project:s"=>\$Project, "RQC"=>\$RQC, "DQC"=>\$DQC, "templateR:s"=>\$TemplateR, "templateD:s"=>\$TemplateD, "help"=>\$Help);

&usage() if ((@ARGV < 1) || $Help || !($RQC || $DQC));

my $Outdir = shift;
mkdir $Outdir unless (-d $Outdir);

my ($typeD, $typeR, $reviewer, $date);

#type
if ($PT eq "BAC-WGRS") { $typeD = "BAC-WGRS"; $typeR = "BAC-WGRS";}
elsif ($PT eq "BAC-denovo" && $AT == 4) { $typeD = "BAC-complete_Denovo\\\(Hiseq2000\\\)"; $typeR = "BAC-denovo_Complete";}
else { $typeD = "BAC-Denovo\\\(Hiseq2000\\\)"; $typeR = "BAC-denovo";}

$Project =~ s/^mgtest$/Mgtest_xxx/g;
chomp ($reviewer = `whoami`);
$date = &date;

my $temp;
if ($DQC) {
	my $name = "DQC-CDTS_$typeD\_$Project\_MG_$reviewer\_$date.xlsx";
	if ($PT eq "BAC-WGRS") {$temp = "$TemplateD/DQC-CDTS_BAC-WGRS_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	elsif ($PT eq "BAC-denovo" && $AT == 4) {$temp = "$TemplateD/DQC-CDTS_BAC-complete_Denovo\(Hiseq2000\)_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	else {$temp = "$TemplateD/DQC-CDTS_BAC-Denovo\(Hiseq2000\)_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	if (-e $temp) {
		$temp =~ s/\(/\\\(/g;
		$temp =~ s/\)/\\\)/g;
		`cp $temp $Outdir/$name`;
	}
	else { warn "There isn't DQC template file: $temp!\n";}
}
if ($RQC) {
	my $name = "RQC_$typeR\_$Project\_MG_$reviewer\_$date.xlsx";
	if ($PT eq "BAC-WGRS") {$temp = "$TemplateR/RQC_BAC-WGRS_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	elsif ($PT eq "BAC-denovo" && $AT == 4) {$temp = "$TemplateR/RQC_BAC-denovo_Complete_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	else {$temp = "$TemplateR/RQC_BAC-denovo_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx";}
	(-e $temp) ? (`cp $temp $Outdir/$name`) : (warn "There isn't template RQC file: $temp!\n");
}

#==================== sub function =======================
sub usage {
	die "
	perl copy_RQC_DQC.pl [OPTIONS] <outdir>
	RQC or DQC shoult set one at least.
	OPTIONS:
	--PT <str>        project type, e.g:BAC-denovo,BAC-WGRS, default=BAC-denovo
	--AT <num>        Denovo assembly type:1.Surver, 2.Fine map, 3.Fine map(upgrade), 4.Complete map, default=2
	--project <str>   project_subproject name. default=Mgtest_xxx
	--RQC             get RQC file.
	--DQC             get DQC file.
	--templateR <str> set template dir of RQC file to copy it to <outdir>. [/nas/MG01/DOCUMENTS/QA/06.QAQC_updata/RQC]
	--templateD <str> set template dir of DQC file to copy it to <outdir>. [/nas/MG01/DOCUMENTS/QA/06.QAQC_updata/DQC]
	--help            show this information\n\n";
}

sub date{
	my @date = (localtime())[5,4,3];
	$date[0]+=1900;
	$date[1]++;
	for(@date[1,2]){(length == 1) && ($_ = "0$_");}
	join("",@date[0..2]);
}
__END__

DQC-CDTS_BAC-complete_Denovo(Hiseq2000)_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx
RQC_     BAC-denovo_Complete_           ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx*

DQC-CDTS_BAC-Denovo(Hiseq2000)_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx
RQC_     BAC-denovo_           ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx*

DQC-CDTS_BAC-WGRS_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx
RQC_     BAC-WGRS_ProjectNo_SubProjectCode_MG_Reviewer_Date.xlsx*
