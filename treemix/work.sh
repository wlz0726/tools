#perl phy2ped.pl conGene.all2.phy cow.ped >cow.map
#part.seq.phy cow.ped >cow.map
#/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/plink-1.9/plink --file cow --maf 0.0001 --transpose --recode --tab --out cow 

#perl get_treemix_input_from_tped.pl pop.info chr10.tfam chr10.tped > treemix.input
#gzip -f treemix.input

rm run.sh
for i in {0..11}
do
    treemix -i treemix.input.gz -m $i -root MPS -o $i
    Rscript plot.R $i
done


#perl treemix_fraction.pl 1
#perl /ifshk5/PC_HUMAN_EU/USER/liaoqijun/Yao/Dadi/Yao3/treemix/ld01/cor/treemix_fraction.pl 1
