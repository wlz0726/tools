#! /usr/bin/perl -w
# Using genotype file to get distance matrix for tree building by EMBOSS's FNEIGHBOR
#   Q Xia, et al. (2009) Complete Resequencing of 40 Genomes Reveals Domestication Events and Genes in Silkworm (Bombyx). Science 326:433.
# bindir: /ifshk5/PC_PA_EU/USER/maolikai/bin/myscript/sheep/04.tree/fneibor
use strict;
use warnings;
#$|=1;
#system 'daterr';
if (@ARGV !=1) {
print "perl $0 <tped_predix> > distance_matrix\n";
exit 0;
}
my ($tped_predix)=@ARGV;
#my $usage="Usage: $0 <tped_predix> > distance_matrix\n";
#my $usage="Usage: $0 <genotype_file> [number of samples - 1] [has title ?] > distance_matrix\n";
#my $tped_predix = shift; # genotype file
my %sample; # order of samples in vcf file header. eg. 0=>'BM', # BM001
if(-e "$tped_predix.tfam.gz" ) {open TFAM,"zcat $tped_predix.tfam.gz|" or die $!;}
elsif(-e "$tped_predix.tfam" ) {open TFAM,"$tped_predix.tfam" or die $!;}
else{die "$tped_predix.tfam do not exist\n";}
my $nsample=0;
while(<TFAM>){
    my ($fam,$sam)=(split)[0,1];
    $sample{$nsample}=$sam;
    $nsample++;
}
close TFAM;

if(-e "$tped_predix.tped.gz"){open TPED,"zcat $tped_predix.tped.gz|" or die $!;}
elsif(-e "$tped_predix.tped"){open TPED,"$tped_predix.tped" or die $!;}
else{die "$tped_predix.tped do not exist\n";}
my %iupac=(
    "AA"=>"A","CC"=>"C","GG"=>"G","TT"=>"T",
    "AC"=>"M","CA"=>"M",
    "GT"=>"K","TG"=>"K",
    "CT"=>"Y","TC"=>"Y",
    "AG"=>"R","GA"=>"R",
    "AT"=>"W","TA"=>"W",
    "CG"=>"S","GC"=>"S",
    "NN"=>"N","00"=>"-",
);
print STDERR "# Read 'tped file' and calculate matrix.\n";
my($nloci,%dis);
while(<TPED>){
  next if /^#/;
#last if $.==20000; # test
  chomp;
  my ($chr,$pos)=(split)[0,3];
  $nloci++; # (Aug 19 2014) old: $nloci=$.;
  print STDERR " $." if $.%10000==0;
  my @temp=split;
  my $test_num=scalar@temp;
  my $test_i=4;
  my $new_str=join" ",(@temp)[0..3];
  while($test_i<$test_num){
      my $geno="$temp[$test_i]$temp[$test_i+1]"; 
      my $geno_short=$iupac{$geno};
      $new_str.=" $geno_short";
      $test_i+=2;
}
#===========================  
  my @p=split(/\s+/,$new_str);
  my $num=scalar(@p);
  my @c=@p[4..$num];
  for(my $i=0; $i<$nsample ; $i++){
    next if $c[$i] eq '-';
    for(my $j=$i+1; $j<$nsample ; $j++){
      next if $c[$j] eq '-';
      if($c[$i] eq $c[$j]){
        next;
      } elsif( ($c[$i] eq 'W' && $c[$j] eq 'S') || ($c[$i] eq 'M' && $c[$j] eq 'K') || ($c[$i] eq 'R' && $c[$j] eq 'Y') || ($c[$i] eq 'S' && $c[$j] eq 'W') || ($c[$i] eq 'K' && $c[$j] eq 'M') || ($c[$i] eq 'Y' && $c[$j] eq 'R')) {
        $dis{"$sample{$i}_$sample{$j}"}+=1 ;
      } elsif($c[$i]=~/^[MKYRWS]$/ || $c[$j]=~/^[MKYRWS]$/) {
        $dis{"$sample{$i}_$sample{$j}"}+=0.5;
      } else {
        $dis{"$sample{$i}_$sample{$j}"}+=1 ;
      }
    }
  }
}
close TPED;
print STDERR "\n";

#system 'daterr';
print STDERR "# Output matrix.\n";
print " $nsample\n";
my $key;
for(my $i = 0;$i<$nsample;$i++){
  printf "%-12s",$sample{$i};
  for(my $j=0; $j<$nsample; $j++){
    if($i==$j){
      printf "\t%-12f",0;
      next;
    }

    if($i<$j){
      $key = "$sample{$i}_$sample{$j}";
    } else {
      $key = "$sample{$j}_$sample{$i}";
    }
    $dis{$key}||=0;
    printf "\t%-12f",$dis{$key}/$nloci;
  }
  print "\n";
}

print STDERR "# Done.\n";
#system 'daterr';
