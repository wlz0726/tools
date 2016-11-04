cat  BRM1.psmc GIR1.psmc LQC1.psmc NEL1.psmc LXC1.psmc NYC1.psmc QCC1.psmc YBC1.psmc YNC1.psmc JBC1.psmc JER1.psmc FLV1.psmc HOL1.psmc LIM1.psmc RAN1.psmc> aa;

perl plot_psmc_MAR_SAT_SL.pl -M "BRM1,GIR1,LQC1,NEL1,LXC1,NYC1,QCC1,YBC1,YNC1,JBC1,JER1,FLV1,HOL1,LIM1,RAN1" -u 9.796e-9 -g 5 -x 10000 -X 10000000 -Y 400000 all aa;
rm all*txt all*par *eps *epss aa* *Good;

cat  BRM1.psmc GIR1.psmc LQC1.psmc NEL1.psmc> aa;

perl plot_psmc_MAR_SAT_SL.pl -M "BRM1,GIR1,LQC1,NEL1" -u 9.796e-9 -g 5 -x 10000 -X 10000000 -Y 400000 indicus aa;
rm indicus*txt indicus*par *eps *epss aa* *Good;

cat  LXC1.psmc NYC1.psmc QCC1.psmc YBC1.psmc YNC1.psmc> aa;

perl plot_psmc_MAR_SAT_SL.pl -M "LXC1,NYC1,QCC1,YBC1,YNC1" -u 9.796e-9 -g 5 -x 10000 -X 10000000 -Y 400000 hyb aa;
rm hyb*txt hyb*par *eps *epss aa* *Good;

cat  JBC1.psmc JER1.psmc FLV1.psmc HOL1.psmc LIM1.psmc RAN1.psmc> aa;

perl plot_psmc_MAR_SAT_SL.pl -M "JBC1,JER1,FLV1,HOL1,LIM1,RAN1" -u 9.796e-9 -g 5 -x 10000 -X 10000000 -Y 400000 taurus aa;
rm taurus*txt taurus*par *eps *epss aa* *Good;

