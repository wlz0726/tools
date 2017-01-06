# about input
'AFR.txt','EAS.txt'... are obtained in two steps:
1. download from <ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/psmc/>
2. change to year using mu and generation_time with formula:
`my $time=$a[0]/(2*$mu/$generation_time)`
`my $ne=($a[1]/(4*$mu*1e3))/(1e4)`

===

# run like this:
## 1. plot Ne and MAR_SAT_SL
perl 01.plot.with.MAR_SAT_SL.pl AFR.txt  EAS.txt  EUR.txt  SAS.txt

## 2.plot simply Ne
perl 02.plot.no_MAR_SAT_SL.pl AFR.txt  EAS.txt  EUR.txt  SAS.txt


===

## manually adjust
edit "01.plot.with.MAR_SAT_SL.pl.gnuplot" file
x-rage:            set xran [10000:10000000];
y-rage:            set yran [0:10];
