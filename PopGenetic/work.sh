/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/plink-1.9/plink --bfile ../step1.data/SNP/UnionSet/s2/UnionSet.Chr10 --transpose --recode --tab --out Chr10
perl add_ance.pl /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step2.ancestry/Chr10.rs.geneticmap.ref.mutus.ancestry.gz Chr10.tped final_ance.tped; gzip -f final_ance.tped 
perl dist_matrix.pl final_ance >distance_matrix
#fneighbor -datafile ./distance_matrix -outfile ./fneibor.tree1 -matrixtype s -treetype n -outtreefile ./fneibor.tree2 >./2.out 2>./2.err

