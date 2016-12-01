for i in {1..26}
  do
  for j in Wild Other #Iran Kazakh Mongolia Tibetan Other
    do
    echo "/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/plink-1.9/plink --bfile ../phasing/chr$i --sheep --keep s1/$j.samplelist  --maf 0.05 --geno 1 --make-bed --out s1/$j.chr$i" >>run.sh
  done
  
  echo "less s1/Wild.chr$i.bim s1/Iran.chr$i.bim s1/Kazakh.chr$i.bim s1/Mongolia.chr$i.bim s1/Tibetan.chr$i.bim s1/Other.chr$i.bim |cut -f 2 |sort|uniq > s1/chr$i.snplist " >> run2.sh
done
