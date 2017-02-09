cat BRM.txt GIR.txt NEL.txt QCC.txt FLV.txt HOL.txt JBC.txt LIM.txt RAN.txt> all;
perl plot_Ne_SAT_SL.pl -M "BRM,GIR,NEL,QCC,FLV,HOL,JBC,LIM,RAN" -u 9.796e-9 -g 5 -x 1000 -w 4 -R 04.plot.Ne.SAT_SL.pl all
rm all
