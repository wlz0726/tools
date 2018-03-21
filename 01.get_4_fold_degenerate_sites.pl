#! /usr/bin/env perl
use strict;
use warnings;
use Bio::SeqIO;

my $introduction="This script is used for identify 4 fold degenerate sites from a genome with the help of gene annotation file.";

my ($genome_file,$gff_file,$fold)=@ARGV;

die "Introduction: $introduction\nUsage: $0 <genome file> <gff file> <4 fold degeneration sites output>\n" if(@ARGV < 3);

my %gff;
open(I,"< $gff_file");
my $no=0;
while(<I>){
    chomp;
    next if(/^#/);
    my @a=split(/\s+/);
    next unless($a[2] eq "CDS");
    $no++;
    my ($chr,$start,$end,$strand,$phase,$name)=($a[0],$a[3],$a[4],$a[6],$a[7],$a[8]);
    # $chr=~s/chr//g;
    $name=~/Parent=([^;]+)/;
    $name=$1;
    $gff{$chr}{$name}{$no}{start}=$start;
    $gff{$chr}{$name}{$no}{end}=$end;
    $gff{$chr}{$name}{$no}{strand}=$strand;
    $gff{$chr}{$name}{$no}{phase}=$phase;
}
close I;

print STDERR "GFF reading complete!\n";

my $fa=Bio::SeqIO->new(-file=>$genome_file,-format=>'fasta');

my $control=0;
open(O,"> $fold");
while(my $seq=$fa->next_seq){
    my $chr=$seq->id;
    my $seq=$seq->seq;
    next unless(exists $gff{$chr});

    foreach my $name(keys %{$gff{$chr}}){
        my $strand="NA";
        my $line="";
        # die "debug" if($control++>100);
        foreach my $no(sort { $gff{$chr}{$name}{$a}{start} <=> $gff{$chr}{$name}{$b}{start} } keys %{$gff{$chr}{$name}}){
            if($strand eq "NA"){
	$strand=$gff{$chr}{$name}{$no}{strand};
            }
            my $start=$gff{$chr}{$name}{$no}{start};
            my $end=$gff{$chr}{$name}{$no}{end};
            my $len=$end-$start+1;
            my $subline=substr($seq,$start-1,$len);
            $line.=$subline;
        }

        my @fold_sites_location_in_genome;

        if($strand eq "+"){
            my $pep = &translate_nucl($line);

            my @fold_sites_location_in_cds = &get_location_in_cds($line);

            next if(scalar(@fold_sites_location_in_cds) == 0);

            my %corresponding_postion;
            my $accumulating_length=0;
            foreach my $no(sort { $gff{$chr}{$name}{$a}{start} <=> $gff{$chr}{$name}{$b}{start} } keys %{$gff{$chr}{$name}}){
	my $start=$gff{$chr}{$name}{$no}{start};
	my $end=$gff{$chr}{$name}{$no}{end};
	my $len=$end-$start+1;

	my $real_start=$start;
	my $real_end  =$end;
	my $cds_start =$accumulating_length+1;
	my $cds_end   =$accumulating_length+$len;

	my $real_pos=$real_start;
	for(my $i=$cds_start;$i<=$cds_end;$i++){
	    my $cds_pos=$i;
	    $corresponding_postion{$cds_pos}=$real_pos;
	    $real_pos++;
	}
	$accumulating_length+=$len;
            }
            foreach my $cds_pos(@fold_sites_location_in_cds){
	my $real_pos=$corresponding_postion{$cds_pos};
	push @fold_sites_location_in_genome,$real_pos;
            }
        }
        elsif($strand eq "-"){
            $line=reverse($line);
            $line=~tr/ATCGatcg/TAGCtagc/;
            my $pep = &translate_nucl($line);

            my @fold_sites_location_in_cds = &get_location_in_cds($line);

            next if(scalar(@fold_sites_location_in_cds) == 0);

            my %corresponding_postion;
            my $accumulating_length=0;
            foreach my $no(sort { $gff{$chr}{$name}{$b}{start} <=> $gff{$chr}{$name}{$a}{start} } keys %{$gff{$chr}{$name}}){
	my $start=$gff{$chr}{$name}{$no}{start};
	my $end=$gff{$chr}{$name}{$no}{end};
	my $len=$end-$start+1;

	my $real_start=$start;
	my $real_end  =$end;
	my $cds_start =$accumulating_length+1;
	my $cds_end   =$accumulating_length+$len;

	my $real_pos=$real_end;
	for(my $i=$cds_start;$i<=$cds_end;$i++){
	    my $cds_pos=$i;
	    $corresponding_postion{$cds_pos}=$real_pos;
	    $real_pos--;
	}
	$accumulating_length+=$len;
            }
            foreach my $cds_pos(@fold_sites_location_in_cds){
	my $real_pos=$corresponding_postion{$cds_pos};
	push @fold_sites_location_in_genome,$real_pos;
            }
        }

        foreach my $pos(@fold_sites_location_in_genome){
            print O "$chr\t$pos\t$name\n";
        }

        print STDERR "$chr\t$name\n";
    }
}
close O;

sub get_location_in_cds{
    my $line=shift;
    my @location;
    my $len=length($line);

    if($len == 0){
        return(@location);
    }

    my @bases=split("",$line);
    my @ATCG=("A","T","C","G");

    for(my $i=0;$i<$len;$i+=3){
        next if(!$bases[$i] or !$bases[$i+1] or !$bases[$i+2]);
        my @codon_bases=($bases[$i],$bases[$i+1],$bases[$i+2]);
        my $codon_bases=join "",@codon_bases;
        $codon_bases=~tr/atcg/ATCG/;
        next if($codon_bases=~/[^ATCG]/);
        my $codon_pep  = &translate_nucl($codon_bases);

        for(my $j=0;$j<3;$j++){
            my $light = 1;
            my @new_codon_bases = @codon_bases;
            foreach my $bases(@ATCG){
	$new_codon_bases[$j]=$bases;
	my $new_codon_bases = join "",@new_codon_bases;
	my $new_codon_pep   = &translate_nucl($new_codon_bases);
	if($new_codon_pep ne $codon_pep){
	    $light=0;
	    last;
	}
            }
            if($light == 1){
	my $location_in_cds=$i+$j+1;
	push @location,$location_in_cds;
            }
        }
    }
    my $number=@location;
    print STDERR " $number four-fold-degenerate-sites in this gene\n";
    return(@location);
}

sub translate_nucl{
    my $seq=shift;
    my $seq_obj=Bio::Seq->new(-seq=>$seq,-alphabet=>'dna');
    my $pro=$seq_obj->translate;
    $pro=$pro->seq;
    return($pro);
}
