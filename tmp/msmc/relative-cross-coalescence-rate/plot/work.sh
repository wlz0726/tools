#cat LQC_GIR.outfile.final.txt LQC_NEL.outfile.final.txt > aa
perl plot_rate_MAR.pl -M "LQC-GIR,LQC-NEL" -u 9.796e-9 -g 5 -x 1000 -X 100000 -w 6 -R  -P "left top" -Y 1.1 all aa