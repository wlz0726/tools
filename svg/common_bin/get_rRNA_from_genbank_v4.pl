#!/usr/bin/perl

=head1 Name

parse genbank format file

=head1 Description

get needed information form genbank format files

=head1 Version

  Author: Fan Wei, fanw@genomics.org.cn
  Version: 2.0,  Date: 2009-1-17

=head1 Usage

  --verbose   output verbose information to screen  
  --help      output help information to screen  

=head1 Exmple



=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname); 
use Data::Dumper;

my ($Verbose,$Help);
GetOptions(
	"verbose"=>\$Verbose,
	"help"=>\$Help
);
die `pod2text $0` if (@ARGV == 0 || $Help);

my $genbank_file = shift;
my %Gene;

parse_genbank($genbank_file,\%Gene);

#generate_seq_file(\%Gene,$genbank_file.".seq");
#generate_cds_file(\%Gene,$genbank_file.".cds");
#generate_ffn_file(\%Gene,$genbank_file.".ffn");
#generate_pep_file(\%Gene,$genbank_file.".pep");
#generate_gff_file(\%Gene,$genbank_file.".gff");
generate_rRNA_file(\%Gene,$genbank_file.".rRNA.fa");
####################################################
################### Sub Routines ###################
####################################################
## read genbank format file
####################################################

sub generate_seq_file{
	my ($hash,$file) = @_;
	open OUT,">".$file || die "fail $file";
	foreach my $ACCESSION (sort keys %$hash) {
		my $seq_str = uc $hash->{$ACCESSION}{SEQ};
		Display_seq(\$seq_str);
		print OUT ">$ACCESSION  [$hash->{$ACCESSION}{ORGANISM}]  $hash->{$ACCESSION}{DEFINITION}\n$seq_str";
	}
	close OUT;
}



sub generate_cds_file{
	my ($hash,$file) = @_;
	open OUT,">".$file || die "fail $file";
	foreach my $ACCESSION (sort keys %$hash) {
		my $output;
		my $cds_hash = $hash->{$ACCESSION}{CDS};
		foreach my $gene (sort keys %$cds_hash) {
			my $strand = $cds_hash->{$gene}{is_complement} ? '-' : '+';
			my $status = $cds_hash->{$gene}{is_partial} ? "partial gene" : "complete gene";
			my $coor_p = $cds_hash->{$gene}{cds};
			my $gene_name = $cds_hash->{$gene}{gene};
			my $cds_str;
			next unless($coor_p);
			for (my $i=0; $i<@$coor_p; $i+=2) {
				$cds_str .= substr($hash->{$ACCESSION}{SEQ},$coor_p->[$i]-1,$coor_p->[$i+1]-$coor_p->[$i]+1);
			}
			Complement_Reverse(\$cds_str) if($cds_hash->{$gene}{is_complement});
			Display_seq(\$cds_str);
			$cds_str = uc $cds_str;
			#print ">$gene  sequence:$ACCESSION:$coor_p->[0]:$coor_p->[-1]:$strand  $cds_hash->{$gene}{note}\n$cds_str";	
			$output .= ">$gene  $gene_name  sequence:$ACCESSION:$coor_p->[0]:$coor_p->[-1]:$strand  $cds_hash->{$gene}{note}  $status\n$cds_str";
		} 
		print OUT $output;
	}
	close OUT;
}

sub generate_ffn_file{
    my ($hash,$file) = @_;
    open OUT,">".$file || die "fail $file";
    foreach my $ACCESSION (sort keys %$hash) {
        my $output;
        my $cds_hash = $hash->{$ACCESSION}{CDS};
        my $version = $hash->{$ACCESSION}{VERSION};
        my $organism =$hash->{$ACCESSION}{ORGANISM};
        foreach my $gene (sort keys %$cds_hash) {
            my $strand = $cds_hash->{$gene}{is_complement} ? 'c' : '';
            my $coor_p = $cds_hash->{$gene}{cds};
            my $coor_p = $cds_hash->{$gene}{cds};
            my $cds_str;
            next unless($coor_p);
            for (my $i=0; $i<@$coor_p; $i+=2) {
                $cds_str .= substr($hash->{$ACCESSION}{SEQ},$coor_p->[$i]-1,$coor_p->[$i+1]-$coor_p->[$i]+1);
            }
            Complement_Reverse(\$cds_str) if($cds_hash->{$gene}{is_complement});
            Display_seq(\$cds_str);
            $cds_str = uc $cds_str;
            $output .= ">ref\|$version\|:$strand$coor_p->[0]\-$coor_p->[-1] $cds_hash->{$gene}{product} \[$organism\]\n$cds_str";
        }
        print OUT $output;
    }
    close OUT;
}

sub generate_pep_file{

	my ($hash,$file) = @_;
	open OUT,">".$file || die "fail $file";
	foreach my $ACCESSION (sort keys %$hash) {
		my $output;
		my $cds_hash = $hash->{$ACCESSION}{CDS};
		foreach my $gene (sort keys %$cds_hash) {
			my $strand = $cds_hash->{$gene}{is_complement} ? '-' : '+';
			my $status = $cds_hash->{$gene}{is_partial} ? "partial gene" : "complete gene";
			my $coor_p = $cds_hash->{$gene}{cds};
			my $pep_str = $cds_hash->{$gene}{protein};
			my $gene_name = $cds_hash->{$gene}{gene};
			Display_seq(\$pep_str);
			
			$output .= ">$gene  $gene_name  sequence:$ACCESSION:$coor_p->[0]:$coor_p->[-1]:$strand  $cds_hash->{$gene}{note}  $status\n$pep_str";
		} 
		print OUT $output;
	}
	close OUT;
}


sub generate_gff_file{
	my ($hash,$file) = @_;
	open OUT,">".$file || die "fail $file";
	foreach my $ACCESSION (sort keys %$hash) {
		my $output;
		my $cds_hash = $hash->{$ACCESSION}{CDS};
		foreach my $gene (sort keys %$cds_hash) {
			my $strand = $cds_hash->{$gene}{is_complement} ? '-' : '+';
			my $status = $cds_hash->{$gene}{is_partial} ? "partial gene" : "complete gene";
			my $coor_p = $cds_hash->{$gene}{cds};
			my $gene_name = $cds_hash->{$gene}{gene};
			$output .= "$ACCESSION\tGenBank\tmRNA\t$coor_p->[0]\t$coor_p->[-1]\t.\t$strand\t.\tID=$gene; $gene_name  $cds_hash->{$gene}{note}  $status\n";
			for (my $i=0; $i<@$coor_p; $i+=2) {
				my ($exon_start,$exon_end) = ($coor_p->[$i], $coor_p->[$i+1]);
				$output .= "$ACCESSION\tGenBank\tCDS\t$exon_start\t$exon_end\t.\t$strand\t.\tParent=$gene;\n";
			}
		} 
		print OUT $output;
	}
	close OUT;
}


sub generate_rRNA_file{
   my ($hash,$file) = @_;
   open OUT,">".$file || die "fail $file";
   my $flag=0;
   foreach my $ACCESSION (sort keys %$hash) {
       my $output;
       my $rRNA_hash = $hash->{$ACCESSION}{rRNA};
       foreach my $gene (sort {$rRNA_hash->{$a}{rRNA}->[0] <=> $rRNA_hash->{$b}{rRNA}->[0]} keys %$rRNA_hash){
           my $strand = $rRNA_hash->{$gene}{is_complement} ? '-' : '+';
           my $status = $rRNA_hash->{$gene}{is_partial} ? "partial gene" : "complete gene";
           my $gene_name = $rRNA_hash->{$gene}{gene};
           my $product = $rRNA_hash->{$gene}{product};
           my $rRNA_p = $rRNA_hash->{$gene}{rRNA};
           next unless($rRNA_p);
           my $rRNA_str;
           for (my $i=0; $i<@$rRNA_p; $i+=2){
               $rRNA_str .= substr($hash->{$ACCESSION}{SEQ},$rRNA_p->[$i]-1,$rRNA_p->[$i+1]-$rRNA_p->[$i]+1);
           }
           Complement_Reverse(\$rRNA_str) if($rRNA_hash->{$gene}{is_complement});
           Display_seq(\$rRNA_str);
           $rRNA_str = uc $rRNA_str;
           $flag++;
           my $NS;
           $NS=(split /\s/,$rRNA_hash->{$gene}{product},2)[0] if($rRNA_hash->{$gene}{product}=~/\d+S ribosomal RNA/);
           $NS=$1 if($rRNA_hash->{$gene}{product}=~/^ribosomal RNA\s+(\d+S)/);
           $NS=$1 if($rRNA_hash->{$gene}{product}=~m/ribosomal RNA-(\d+S)/);
           $output .= ">flag$flag#rRNA\_$NS\tref|$ACCESSION|:$rRNA_p->[0]-$rRNA_p->[-1]|$rRNA_hash->{$gene}{product}| \[locus_tag=$gene\]\n$rRNA_str"; 
       }
       print OUT $output;
   }
   close OUT;
}



sub parse_genbank {
	my $file = shift;
	my $hash = shift;
	
	open IN,$file  || die "fail $file";
	$/="LOCUS       ";
	<IN>;
	while (<IN>) {
		chomp;
		$_ = "LOCUS       ".$_;
		my ($locus,$len,$type,$class,$ACCESSION,$VERSION,$ORGANISM,$DEFINITION,$ORF,$seq,%cds,%rRNA);
		($locus,$len,$type,$class) = ($1,$2,$3,$4) if(/LOCUS\s+(\S+)\s+(\d+)\s+bp\s+(\S+)\s+\S+\s+(\S+)/);
		$locus = $1 if(/LOCUS\s+(\S+)/);

		next unless($locus);
		$ACCESSION = $1 if(/\nACCESSION\s+(\S+)/);
        $VERSION = $1 if(/\nVERSION\s+(\S+)\s+/);    
		$ORGANISM = $1 if(/\n\s+ORGANISM\s+(.+)/);
		$DEFINITION = $1 if(/\nDEFINITION\s+(.+?)\s+ACCESSION/s);
		$DEFINITION =~ s/\n           //g;
		
		$seq = $1 if(/\nORIGIN(.+?)\/\//s);      
		$seq =~ s/\s+\d+\s+//g;
		$seq =~ s/\s//g;

		while (/(CDS             .+?\n)     \S/sg) {
			parse_CDS($1,\%cds);
#print $1,"\n";
		}
        while (/(rRNA            .+?\n)     \S/sg){
            parse_rRNA($1,\%rRNA);
        }

		$hash->{$ACCESSION}{LOCUS} = $locus;
		$hash->{$ACCESSION}{LEN} = $len;
		$hash->{$ACCESSION}{TYPE} = $type;
		$hash->{$ACCESSION}{CLASS} = $class;
        $hash->{$ACCESSION}{VERSION} = $VERSION;
		$hash->{$ACCESSION}{ORGANISM} = $ORGANISM;
		$hash->{$ACCESSION}{DEFINITION} = $DEFINITION;
		$hash->{$ACCESSION}{SEQ} = $seq;
		$hash->{$ACCESSION}{CDS} = \%cds;
        $hash->{$ACCESSION}{rRNA} = \%rRNA;
		##warn "$ACCESSION parsed";
	
	}
	$/="\n";
	close IN;
}


sub parse_CDS{
	my $str = shift;
	my $hash = shift;
	
	my ($gene,$protein,$note,$is_partial,$is_complement,$locus_tag,$product);
	$is_complement = 1 if($str =~ /CDS             complement\(/);
    $product = $1 if($str =~ /\/product=\"(.+?)\"/s);
	$protein = $1 if($str =~ /\/translation=\"(.+?)\"/s);
	$protein =~ s/\s//g;
	
	$gene = $1 if($str =~ /\/gene=\"(.+?)\"/s);
	$locus_tag = $1 if($str =~ /\/locus_tag=\"(.+?)\"/s);

	while ($str =~ /\/note=\"(.+?)\"/sg) {
		$note .= $1.";  ";
	}
	$note =~ s/\n//g;
    $note =~ s/->/-/g;
	
	my @cds;
	while ($str =~ /([\d><]+\.\.[\d><]+)[\n\)]/sg) {
		my $coor_str = $1;
		$is_partial = 1 if($coor_str =~ /[><]/);
		$coor_str =~ s/[><]//g;
		my ($start,$end) = ($1,$2) if($coor_str =~ /(\d+)\.\.(\d+)/);
		push @cds,$start,$end;
	}
	
	$hash->{$locus_tag}{protein} = $protein;
	$hash->{$locus_tag}{note} = $note;
	$hash->{$locus_tag}{is_partial} = $is_partial;
	$hash->{$locus_tag}{is_complement} = $is_complement;
	$hash->{$locus_tag}{cds} = \@cds;
	$hash->{$locus_tag}{gene} = $gene;
    $hash->{$locus_tag}{product} = $product;
}



sub parse_rRNA{
    my $str = shift;
    my $hash = shift;

    my ($is_complement,$is_partial,$gene,$locus_tag,$product);
    my @rRNA;
    $is_complement = 1 if($str =~ /rRNA            complement\(/);
    while ($str =~ /([\d><]+\.\.[\d><]+)[\n\)]/sg){
        my $coor_str = $1;
        $is_partial =1 if($coor_str =~ /[><]/);
        $coor_str =~ s/[><]//g;
        my ($start,$end) = ($1,$2) if($str=~/(\d+)\.\.(\d+)/);
        push @rRNA,$start,$end;
    }
    $gene = $1 if($str =~ /\/gene=\"(.+?)\"/s);
    $locus_tag = $1 if($str =~ /\/locus_tag=\"(.+?)\"/s);
    $product = $1 if($str =~ /\/product=\"(.+?)\"/s);
    
    $hash->{$locus_tag}{is_complement} = $is_complement;
    $hash->{$locus_tag}{is_partial} = $is_partial;
    $hash->{$locus_tag}{gene} = $gene;
    $hash->{$locus_tag}{product} = $product;
    $hash->{$locus_tag}{rRNA} = \@rRNA;
}



#display a sequence in specified number on each line
#usage: disp_seq(\$string,$num_line);
#		disp_seq(\$string);
#############################################
sub Display_seq{
	my $seq_p=shift;
	my $num_line=(@_) ? shift : 70; ##set the number of charcters in each line
#my $num_line=(@_) ? shift : 70; ##set the number of charcters in each line
	my $disp;

	$$seq_p =~ s/\s//g;
	for (my $i=0; $i<length($$seq_p); $i+=$num_line) {
		$disp .= substr($$seq_p,$i,$num_line)."\n";
	}
	$$seq_p = ($disp) ?  $disp : "\n";
}
#############################################

##complement and reverse the given sequence
#usage: Complement_Reverse(\$seq);
#############################################
sub Complement_Reverse{
	my $seq_p=shift;
	if (ref($seq_p) eq 'SCALAR') { ##deal with sequence
		$$seq_p=~tr/AGCTagct/TCGAtcga/;
		$$seq_p=reverse($$seq_p);  
	}
}
#############################################


__END__

CDS             <28565295..28566005

join(<28659567..28660665,28660762..28661126)
complement(join(28651303..28651419,28651528..28651604,
                     28651675..28651733,28652238..28652311,28652400..28652450,
                     28652538..28652605,28652888..28652972,28653459..28653680))


CDS             join(84379..84600,84737..84830,84935..85086,85212..85299,
                     85399..86681,87291..87398,87500..87583)
                     /codon_start=1
                     /gene="Os01g0101800"
                     /note="Conserved hypothetical protein"
                     /note="supported by AK103498"
                     /protein_id="BAF03659.1"
                     /transl_table=1
                     /translation="MPTQHLTSRRHAELLRHLLLDGGAAVKDLRLRRVVPLTSAPLDD
                     SSPDPAGPAAKSGSAETTPPEAQDGRERKPVVQRSKLVHAPASFGYRRLLPFLNQLTN
                     TNQESECPSGKDNSKIDAYAESESEAQPDPVHCSISTTKEEINISSSHLSSTKMCLSR
                     CQRSRFVHHPSSFSYKRMLPFVTENEITSQEGHRTKIPRLVQEKQSSTDENLILTTGQ
                     HHFVMSGDSAEECKTAQVERLVEENESKSDRIHPLGGRLLQPAVSEAAHLELQVSTVE
                     GQNLTQERVLASDAHLLSSDKGECTLKWNDVLPAGQHQPAASEDFSEESNKAGVEAVL
                     EERKSVPDGNSVLDGRQLQTFVSKASPPEGTAEMQKATQKQAVTSDGDDDPLDSCKGG
                     SLAKEQPLLHATELSVKDNAEGDEVHQCQSPELGTSDVCFGGPTKVVIPSVNSHNALE
                     QCDSMASLDEPLLDVEMTCIPLDPCATGVPYSVKETPAGVLCTSDHCSTGTPLTVEET
                     SSSVSVVHIEPMSSKVSPVRQRGSPCLEKRGLSPKKLSPKKGILKRHTRGCKGICMCL
                     DCSTFRLRADRAFEFSRKQMQEADDIIDNLLKEVSSLRNLMEKSAGQQETKQTACQRA
                     SQVEVVARERRRQMLMELNSHCRIPGPRVKFAQYVEERMASSPSPDSPSRRR"
