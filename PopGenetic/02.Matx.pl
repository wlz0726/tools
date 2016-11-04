my $tfile=shift;
die "$0 tfile\n"unless $tfile;

open(O,"> $tfile.sh");
print O "perl dist_matrix.pl $tfile > $tfile.matrix.phylip;
perl 3.phylip.pl $tfile.matrix.phylip $tfile.matrix.phylip.outfile $tfile.matrix.phylip.tree ;
/opt/blc/genome/biosoft/phylip-3.69/bin/neighbor 0<$tfile.matrix.phylip.config;
mv outfile $tfile.matrix.phylip.outfile;
mv outtree $tfile.matrix.phylip.tree;
\n";
close O;
