my $dir=shift;
die "$0 dir\n" unless $dir;
open(O,"> $dir.2.merge.sh");
print O "cat $dir/Chr*.anc.tped > $dir.tped;cat $dir.tped|gzip -c > $dir.tped.gz;
ln -s final_ance.rename.tfam $dir.tfam;
ln -s final_ance.rename.tfam.gz $dir.tped.gz;
\n";
close O;
