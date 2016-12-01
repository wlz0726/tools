#!/usr/bin/perl -w
my $oboFile=shift;
my %DirectRoot;
my $outFile1="01.GOfromLeafToDirectRoot.list";

open(O,'>',$outFile1);
print O "#child\tname\tnamespace\tdirectRoot\taltID\n";
$/='[Term]';
open(F,$oboFile);
while(<F>){
  chomp;
  my ($id,$name,$namespace,@parent);
  if(/id: (GO:\S+)/){
    $id=$1;
  }else{
    next;
  }
  my @altID;
  if(/is_obsolete: true/){
    next;
  }
  my @a=split("\n",$_);
  foreach my $a(@a){
    if($a=~m/^name: (.*)$/){
      $name=$1;
    }elsif($a=~m/^namespace: (.*)$/){
      $namespace=$1;
    }elsif($a=~m/is_a: (GO:\S+)/){
      push @parent,$1;
    }elsif($a=~m/alt_id: (GO:\S+)/){
      push @altID,$1;
    }
  }
  print O "$id\t$name\t$namespace\t",join(";",@parent),"\t";
  if(@altID==0){
    print O "-\n";
  }else{
    print O join(";",@altID),"\n";
  }


}
close(F);
$/="\n";
close(O);
