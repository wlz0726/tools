#!/usr/bin/perl -w
my $DirectParent=shift;
my $outFile="02.GOfromLeafToAllRoot.list";
my %GOdirect;
open(F,$DirectParent);
while(<F>){
  chomp;
  next if(/^#/);
  my @a=split("\t",$_);
  
  my @parent=split(";",$a[3]);
  $GOdirect{$a[0]}{name}=$a[1];
  $GOdirect{$a[0]}{namespace}=$a[2];
  
  foreach my $parent(@parent){
    $GOdirect{$a[0]}{DirectParent}{$parent}++;
   
  }
=cut
  if($a[4]=~m/-/){

  }else{
    my @altID=split(";",$a[4]);
    foreach my $altID(@altID){
      $GOdirect{$altID}{name}=$a[1];
      $GOdirect{$altID}{namespace}=$a[2];
      foreach my $parent(@parent){
        $GOdirect{$altID}{DirectParent}{$parent}++;
      }
    }
  }
=cut
}
close(F);





open(O,'>',$outFile);
print O "#leaf\tname\tnamespace\tAllroot\n";
foreach my $GO(keys %GOdirect){
  print "$GO\n";
  my @AllParent=&findAllRoot($GO,%GOdirect);
  my %Allroot;
  $Allroot{$GO}++;
  foreach my $AllParent(@AllParent){
    $Allroot{$AllParent}++;
  }
  print O "$GO\t$GOdirect{$GO}{name}\t$GOdirect{$GO}{namespace}\t";
  print O join(";",keys %Allroot),"\n";
}
close(O);

sub findAllRoot{
  my ($leaf,%go)=@_;
  my @up;
  if(exists $go{$leaf}{DirectParent}){
    foreach my $up(keys %{$go{$leaf}{DirectParent}}){
      push @up,$up;
      push @up,&findAllRoot($up,%go);
    }
  }
  return @up;
}
