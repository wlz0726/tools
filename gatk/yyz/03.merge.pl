use strict;
use warnings;
use FileHandle;
my %fh;

my $dir="03.merge";
`mkdir $dir` if (! -e "$dir");
my @id=("Cco02","Cco03","Cfr01","Oda00","Omu01","Omu02","Omu03","Omu04","Omu05","Omu06","Omu07","Omu08","Omu09","Omu10","Omu11","Omu12","Omu13","Omu14","Ore00","Ore01","Ore02","Ore03","Ore04","Ore11","Ore12","Ore13","Ore14","Ore15","Ore17","Ore18","Ore19","Ore20");
for (my $i=1;$i<=2084;$i++){
    for my $id (@id){
        my $vcf="01.vcfByWindow/$i/$id.gvcf.gz";
        if ($i == 1){
            $fh{$id}=FileHandle->new("> $dir/$id.g.vcf");
        }
        open (F,"zcat $vcf|");
        while (<F>) {
            chomp;
            my @a=split(/\t/,$_);
            if (/^#/){
	next if $i>1;
	next if /^##GATKCommandLine.HaplotypeCaller/;
	next if /^##GVCFBlock/;
            }
            $fh{$id}->print ("$_\n");
        }
        close F;
        #last;
    }
}

for my $filehandlename (sort keys %fh){
    $fh{$filehandlename}->close();
}
