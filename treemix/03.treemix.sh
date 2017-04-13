for i in {1..11}
do
  echo "/home/wanglizhong/software/treemix/treemix-1.12/src/treemix -i treemix.input.gz -k 1 -m $i -root AF-YRI,AF-LWK,AF-GWD,AF-MSL,AF-ESN,AF-ASW,AF-ACB -o 03.treemix.$i ; /ifshk4/BC_PUB/biosoft/PIPE_RD/Package/R-3.1.1/bin/Rscript plot.R 03.treemix.$i"
done

