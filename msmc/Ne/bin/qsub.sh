rm o_*
split -l 1 run.sh o_
for i in o_*; do qsub -cwd -l vf=0.4G, -l p=1 -q bc.q -P CATwiwR $i; done;