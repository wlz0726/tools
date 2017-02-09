cat BRM.txt GIR.txt NEL.txt FLV.txt HOL.txt JBC.txt LIM.txt RAN.txt> all;
perl plot_Ne_MAR.pl -M "BRM,GIR,NEL,FLV,HOL,JBC,LIM,RAN" -u 9.796e-9 -g 5 -x 1000 -w 6 -R 03.plot.Ne_MAR.pl all
