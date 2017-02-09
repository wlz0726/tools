#!/usr/bin/perl -w

use strict;

if(@ARGV == 0){
	print "perl $0 <Scafflie> <long_SE_read1_soap> <long_SE_read2_soap> <min_insize> <max_insize> <cutlen> <output read file prefix>\n";
	exit;
}

my ($readID,$readSeq,$read1Seq,$readQual,$read1Qual,$rep,$readlen,$read1len,$reverse,$reverse1,$Scafname,$Scafname1,$Scafpos,$Scafpos1);
my ($ScafSeq,%Scaf_len,%Read1_soap,$min_insize,$max_insize,$cutlen,$len1,$len2,$len1_1,$len2_1,$i);
$min_insize = $ARGV[3];
$max_insize = $ARGV[4];
$cutlen = $ARGV[5];
$i = 0;
print "min_insize: $min_insize\tmax_insize: $max_insize\tcutlen: $cutlen\n";
open IN,"<$ARGV[0]" or die;
$/ = ">";
while(<IN>){
	s/>//;
	if($_ eq ""){next;}
	$Scafname = (split /\s+/,(split /\n/,$_)[0])[0];
	$ScafSeq = (split /\n/,$_,2)[1];
	$ScafSeq =~ s/[\n\r]//g;
#print "$Scafname\n$ScafSeq\n";
	$Scaf_len{$Scafname} = length($ScafSeq);
}
$/= "\n";
close IN;
$ScafSeq = "";
foreach(keys %Scaf_len){
	print "$_\t$Scaf_len{$_}\n";
}

open IN,"<$ARGV[1]" or die;
print "######################Read soap_read1 $ARGV[1]####################\n";
#  FC42C7LAAXX:5:1:3:1092/1      GTGTGGGACGTGGACCAGGCGATCGCCAGCATGCAGCCCCTCGC    VHP\`]PKDMMVJEZQDYX\WQ__[`_]a`_^`[_a[DQ^a`a`     1       a       44      -       scaffold724     6926    1       G->37C27        44M      37G6
while(<IN>){
	chomp;
	if(/^(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+/){
		if($4 > 1){next;}
		$readID = $1;
		$readID =~ s/\/1//;
		$Read1_soap{$readID} = $_;
#print "$readID\t$readSeq\t$reverse\t$Scafname\t$Scafpos\n";
		$i++;
		if($i % 100000 == 0){
			print "store $i reads\n";
		}
#		if(exists $Read1_soap{$readID}){
#			delete $Read1_soap{$readID};
#print "*****$readID exists\n";
#			next;
#		}
#		$Read1_soap{$readID} = [$readSeq,$readQual,$readlen,$reverse,$Scafname,$Scafpos];
#print "store $readID info\n";
	}
}
close IN;
print "#####################finish read soap_read1#######################\n";
open OUT1,">$ARGV[6]_1.fq" or die;
open OUT2,">$ARGV[6]_2.fq" or die;

open IN,"<$ARGV[2]" or die;
print "######################Read soap_read2 $ARGV[2]####################\n";
while(<IN>){
	chomp;
	if(/^(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+/){
		$readID = $1;
		$readSeq = $2;
		$readQual = $3;
		$rep = $4;
		$readlen = $6;
		$reverse = $7;
		$Scafname = $8;
		$Scafpos = $9;
#print "$readID\t$readSeq\t$reverse\t$Scafname\t$Scafpos\n";
		if($rep > 1){next;}
		$readID =~ s/\/2//;
		if($reverse eq "-"){
			$readSeq = reverse($readSeq);
			$readSeq =~ tr/ATCG/TAGC/;
			$readQual = reverse($readQual);
		}
		if(exists $Read1_soap{$readID}){
#print "exists $readID/1\n";
			if($Read1_soap{$readID} =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+/){
				$read1Seq = $2;
				$read1Qual = $3;
				$read1len = $6;
				$reverse1 = $7;
				$Scafname1 = $8;
				$Scafpos1 = $9;
				if($reverse1 eq "-"){
					$read1Seq = reverse($read1Seq);
					$read1Seq =~ tr/ATCG/TAGC/;
					$read1Qual = reverse($read1Qual);
				}
			}
			if($Scafname eq $Scafname1){
				print "$readID/1 and $readID/2 are in same scaf\n";
				if($reverse eq $reverse1){
					print "$readID/1 and $readID/2 have same direction on same Scaf\n";
					next;
				}
				print "$readID/1 reverse $reverse1  pos : $Scafpos1 \n";
				print "$readID/2 reverse $reverse  pos : $Scafpos \n";
				if($Scafpos1 <= $Scafpos && $reverse1 eq "+"){
					print "$readID/1 $reverse1 pos : $Scafpos1 and $readID/2 $reverse  pos : $Scafpos , wrong\n";
					next;
				}elsif($Scafpos1 > $Scafpos && $reverse eq "+"){
					print "$readID/2 $reverse  pos : $Scafpos and $readID/1 $reverse1 pos : $Scafpos1 , wrong\n";
					next;
				}
				print "$readID/1 and $readID/2 have insize(ex both readlen) ".(abs($Scafpos - $Scafpos1))."\n";
				if(abs($Scafpos - $Scafpos1) - $readlen < $max_insize - $cutlen && abs($Scafpos - $Scafpos1) - $readlen > $min_insize - $cutlen){
					print "$readID/1 and $readID/2 qualified\n";
					print OUT1 "\@$readID/1\n$read1Seq\n+\n$read1Qual\n";
					print OUT2 "\@$readID/2\n$readSeq\n+\n$readQual\n";
					delete $Read1_soap{$readID};
				}
			}else{
				if($reverse1 eq "+"){
					print "$readID/1 +dir at $Scafname1 pos : $Scafpos1  Scaflen is $Scaf_len{$Scafname1}\n";
					$len1 = $Scaf_len{$Scafname1} - $read1len - $Scafpos1;
					$len1_1 = $Scafpos1;
				}elsif($reverse1 eq "-"){
					print "$readID/1 -dir at $Scafname1 pos : $Scafpos1  Scaflen is $Scaf_len{$Scafname1}\n";
					$len1 = $Scafpos1;
					$len1_1 = $Scaf_len{$Scafname1} - $read1len - $Scafpos1;
				}
				if($reverse eq "-"){
					print "$readID/2 -dir at $Scafname pos : $Scafpos  Scaflen is $Scaf_len{$Scafname}\n";
					$len2 = $Scafpos;
					$len2_1 = $Scaf_len{$Scafname} - $readlen - $Scafpos;
				}elsif($reverse eq "+"){
					print "$readID/2 +dir at $Scafname pos : $Scafpos  Scaflen is $Scaf_len{$Scafname}\n";
					$len2 = $Scaf_len{$Scafname} - $readlen - $Scafpos;
					$len2_1 = $Scafpos;
				}
				if($len1 + $len2 + $read1len + $readlen > $cutlen && $len1_1 + $len2_1 < $max_insize - $cutlen){
					print "$readID/1 $reverse1 dir on $Scafname1 and $readID/2 $reverse dir on $Scafname are qualified\n";
					print OUT1 "\@$readID/1\n$read1Seq\n+\n$read1Qual\n";
					print OUT2 "\@$readID/2\n$readSeq\n+\n$readQual\n";
					delete $Read1_soap{$readID};
				}
			}
		}else{
			print "not exists $readID/1\n";
			next;
		}
	}
}
close IN;
print "##################Finish read soap_read2 and out put new readfile################\n";
close OUT1;
close OUT2;
