# run like this:
# plot Ne and MAR_SAT_SL
perl 01.plot.with.MAR_SAT_SL.pl AFR.txt  EAS.txt  EUR.txt  SAS.txt

# plot simply Ne
perl 02.plot.no_MAR_SAT_SL.pl AFR.txt  EAS.txt  EUR.txt  SAS.txt



## manually adjust image:
"01.plot.with.MAR_SAT_SL.pl.gnuplot" 
x-rage:            set xran [10000:10000000];
y-rage:            set yran [0:10];
